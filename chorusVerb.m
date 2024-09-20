classdef chorusVerb < audioPlugin                            % <== (1) Inherit from audioPlugin.
  %%
  % Author: Ryan Baker
  % Email: ryanbakermusic@outlook.com
  % Website: ryanbakermusic.tech
  % University of Miami (B.S. 2024)
  % Georgia Institute of Technology (M.S. 2026)
  % Additional Tasks Responses in ReadMe, screenshots in file
  %%
    properties
        % Define tunable properties
        RoomSizeFactor          = 3;
        PreDelay                = 1200;
        NumberOfBranches        = 16;
        AllPassGain             = 0.7;
        FeedbackGain            = 0.2;
        MixingCoefficient       = 50;
        ShelvingCutOff          = 20000;
        ShelvingGainDB          = -10;
        % EnableDecorrelation     = false;
        ChorusRate = 1;
        ChorusDepth = 20;
        ChorusLevel = 50;
        ToggleChorus = 'Off';
        EarlyRefGain = 0;
        DiffusionGain = 0;
        Wideness = 0;
    end

    properties (Access = private)
        % Define non-tunable properties
        er_L        = zeros(16,4096);       % Early_Reflection State Matrix Left Channel
        er_R        = zeros(16,4096);       % Early_Reflection State Matrix Right Channel
        y_er        = zeros(16,2);          % Output of Early Reflections
        in_d        = zeros(1,4096);        % Delayed Input for FDN
        s_ap        = zeros(16,4096);       % All-Pass Delay State Matrix
        y_o         = zeros(16,4096);       % All-Pass Output State Matrix
        y_d         = zeros(16,1);          % Output of FDN
        hfs_ap      = zeros(16,1);          % State of All-Pass Delay in High-Frequency Shelving
        hfs_ls       = 0;                        %%% last sample of  High-Frequency Shelving for next loop
        a_L         = [-0.2846, 0.2684, -0.2346, 0.2084, -0.1946, 0.1784, -0.1446, 0.1384, ...
                        -0.1246, 0.1384, -0.1546, 0.1484, -0.1646, 0.1584, -0.1146, 0.0884];      % Gain Factor Left Channel
        a_R         = [0.2856, -0.2674, 0.2356, -0.2074, 0.1956, -0.1774, 0.1456, -0.1374, ...
                        0.1256, 0.1374, 0.1556, -0.1474, -0.1656, -0.1574, 0.1156, -0.0874];      % Gain Factor Right Channel
        g_erL       = [-0.5208, -0.4857, 0.2715, -0.3877, 0.2183, 0.1873, -0.2888, -0.1104, ...
                        0.1742, 0.1729, 0.1707, -0.1036, -0.1029, 0.1574, -0.2480, -0.2444];      % Gain Factors for Early Reflections of Left Channel
        g_erR       = [-0.5208, -0.5049, 0.2798, -0.3877, 0.2226, 0.1873, -0.2888, -0.1117, ...
                        0.1742, 0.1729, 0.1727, -0.1047, -0.1040, 0.1574, -0.2444, -0.2411];      % Gain Factors for Early Reflections of Right Channel    
        w_sap       = 1;                    % Write Index of Circular Buffer s_ap
        w_yo        = 1;                    % Write Index of Circular Buffer y_o
        w_ind       = 1;                    % Write Index of Circular Buffer in_d
        w_er        = 1;                    % Write Index of Circular Buffer w_er
        %%% Chorus for Early Reflections
        chorus_buffer = zeros(2, 4096); %stereo chorus buffer
        chorus_idxL = 1; % left index
        chorus_idxR = 1; % right index
        lfo_phase = zeros(2, 1); % stereo phase variables
        roomFactorHasChanged = false; % unused but another safety variable
        storeRSF = 3; % param change safety variables
        storeNB = 16;
    end

    properties (Constant)
        % Map tunable property to plugin parameter
        PluginInterface = audioPluginInterface( ...
            audioPluginParameter("RoomSizeFactor", ...
                DisplayName="Room Size Factor", ...
                DisplayNameLocation="above", ...
                Mapping={'lin',1,7}, ...
                Style="vslider", ...
                Layout=[2 1; 3 1]), ...
            audioPluginParameter("PreDelay", ...
                DisplayName="Pre-Delay", ...
                DisplayNameLocation="above", ...
                Mapping={'int',0,2000}, ...
                Style="vslider", ...
                Layout=[2 2; 3 2]), ...
            audioPluginParameter("NumberOfBranches", ...
                DisplayName="Branches", ...
                DisplayNameLocation="above", ...
                Mapping={'int',2,16}, ...
                Style="vslider", ...
                Layout=[2 3; 3 3]), ...
            audioPluginParameter("AllPassGain", ...
                DisplayName="All-Pass Gain", ...
                DisplayNameLocation="above", ...
                Mapping={'lin',0,0.9}, ...
                Style="rotaryknob", ...
                Layout=[5 1]), ...
            audioPluginParameter("FeedbackGain", ...
                DisplayName="Feedback Gain", ...
                DisplayNameLocation="above", ...
                Mapping={'lin',0,0.9}, ...
                Style="rotaryknob", ...
                Layout=[5 2]), ...
            audioPluginParameter("MixingCoefficient", ...
                DisplayName="Dry/Wet Ratio", ...
                Label = '% Wet', ...
                DisplayNameLocation="above", ...
                Mapping={'lin',0,100}, ...
                Style="rotaryknob", ...
                Layout=[5 3]), ...
            audioPluginParameter("ShelvingCutOff", ...
                DisplayName="Shelving Cut-Off", ...
                DisplayNameLocation="above", ...
                Mapping={'lin',5000,20000}, ...
                Label="Hz", ...
                Style="vslider", ...
                Layout=[2 4; 3 4]), ...
            audioPluginParameter("ShelvingGainDB", ...
                DisplayName="Shelving Gain", ...
                DisplayNameLocation="above", ...
                Mapping={'lin',-40,0}, ...
                Label="dB", ...
                Style="rotaryknob", ...
                Layout=[5 4]), ...
            audioPluginParameter('ChorusRate', ...
                'DisplayName','Chorus Rate', ...
                'Label', 'Hz', ...
                'Style', 'rotaryknob',...
                'Layout',[9,1],...
                'Mapping', {'log', 0.1, 40}), ...
            audioPluginParameter('ChorusDepth', ...
                'DisplayName', 'Chorus Depth',  ...
                'Label', '%', ...
                'Layout',[9,2],...
                'Style', 'rotaryknob',...
                'Mapping', {'lin', 0, 100}), ...
            audioPluginParameter('ChorusLevel', ...
                'DisplayName', 'Chorus Level',  ...
                'Label', '%', ...
                'Layout',[9,3],...
                'Style', 'rotaryknob',...
                'Mapping', {'lin', 0, 100}), ...
            audioPluginParameter('ToggleChorus', ...
                'DisplayName', 'Chorus', ...
                'Style', 'vtoggle',...
                'Layout',[9,4],...
                'Mapping', {'enum', 'On', 'Off'}), ...
            audioPluginParameter('EarlyRefGain', ...
                'DisplayName', 'Reflections Gain', ...
                'Label', 'dB', ...
                'Style', 'rotaryknob',...
                'Layout',[7,1],...
                'Mapping', {'lin', 0, 9}), ...
            audioPluginParameter('DiffusionGain', ...
                'DisplayName', 'Diffusion Gain', ...
                'Label', 'dB', ...
                'Style', 'rotaryknob',...
                'Layout',[7,2],...
                'Mapping', {'lin', 0, 9}), ...
            audioPluginParameter('Wideness', ...
                'DisplayName', 'Wideness', ...
                'Style', 'rotaryknob',...
                'Layout',[7,4],...
                'Mapping', {'lin', 0, 200}), ...
            audioPluginGridLayout( ...
                RowHeight=[30 90 100 30 100 30 100 30, 100, 30], ...
                ColumnWidth=[125 125 125 125], ...
                Padding=[10 10 10 30]), ...
            PluginName="Chorus Room Reverb", ...
            InputChannels=2, ...
            OutputChannels=2);
    end

    methods
        function plugin = chorusVerb()
            plugin.lfo_phase = zeros(2,1);
        end
        % Define audio processing
        function out = process(plugin,in)
            
            numSamples  = length(in);
            % Load cached variables
            [D_p,G_f,er_L,er_R,y_er,in_d,s_ap,y_o,y_d,hfs_ap,hfs_ls,a_L,a_R,g_erL,g_erR,w_idx,b_sz,chorus_buffer,chorus_level, lfo_phase]   = LoadCache(plugin);  

            M           = round(plugin.RoomSizeFactor*[223, 281, 331, 379, 419, 457, 479, 499, 509, 523, 541, 547, 557, 563, 569, 571]);
            M           = M(1:min(plugin.NumberOfBranches,length(M)));
            D           = round(3*plugin.RoomSizeFactor*[53, 59, 67, 73, 79, 89, 97, 101, 107, 113, 127, 137, 149, 157, 167, 179]);
            D           = D(1:min(plugin.NumberOfBranches,length(D)));
            DefaultL = [70, 98, 153, 204, 269, 367, 385, 418, 419, 425, 435, 467, 472, 498, 501, 513];
            L           = round(plugin.RoomSizeFactor*DefaultL);
            L           = L(1:min(plugin.NumberOfBranches,length(L)));
            DefaultR = [70, 82, 139, 204, 258, 367, 385, 409, 419, 425, 426, 458, 464, 498, 513, 525];
            R           = round(plugin.RoomSizeFactor * (DefaultR + plugin.Wideness));% + plugin.Wideness));
            R           = R(1:min(plugin.NumberOfBranches,length(R)));
            numBranches = numel(M);

            


            % Set history of unused branches to 0 
            %%% had to change this part due to some strange artifacting on
            %%% variable change
            if numBranches ~= plugin.storeNB
                er_L(numBranches+1:end,:)       = zeros(16 - numBranches,4096);
                er_R(numBranches+1:end,:)       = zeros(16 - numBranches,4096);    
                y_er(numBranches+1:end,:)       = zeros(16 - numBranches,2);        
                in_d                                          = zeros(1,4096);       
                s_ap(numBranches+1:end,:)       = zeros(16 - numBranches,4096);
                y_o(numBranches+1:end,:)        = zeros(16 - numBranches,4096);
                y_d(numBranches+1:end,:)        = zeros(16 - numBranches,1);
                hfs_ap(numBranches+1:end,:)     = zeros(16 - numBranches,1);
            end
            if plugin.RoomSizeFactor ~= plugin.storeRSF
                er_L        = zeros(16,4096);       % Early_Reflection State Matrix Left Channel
                er_R        = zeros(16,4096);       % Early_Reflection State Matrix Right Channel
                y_er        = zeros(16,2);          % Output of Early Reflections
                in_d        = zeros(1,4096);        % Delayed Input for FDN
                s_ap        = zeros(16,4096);       % All-Pass Delay State Matrix
                y_o         = zeros(16,4096);       % All-Pass Output State Matrix
                y_d         = zeros(16,1);          % Output of FDN
                hfs_ap      = zeros(16,1);          % State of All-Pass Delay in High-Frequency Shelving
            end
            % Generate mono input
            x           = (in(:,1) + in(:,2)) / 2;
            fs          = getSampleRate(plugin);

            % Calculate Shelving Filter Parmaters one per block
            Wc          = 2 * pi * plugin.ShelvingCutOff / fs;
            V0          = 10^(plugin.ShelvingGainDB/20); 
            H0_hfs      = V0 - 1;
            a_hfs       = (1 - tan(Wc/2)*V0) / (1 + tan(Wc/2)*V0);    % High-Frequency Shelving Cut-Case Coefficient

            % Set up chorus
            chorus_delay = 20;
            chorus_depth = plugin.ChorusDepth / 100;
            chorus_level = chorus_level / 100;
            chorus_rate = plugin.ChorusRate; % in Hz
            lfoL = sin(2 * pi * chorus_rate * (0:numSamples-1) / fs + lfo_phase(1));
            lfoR = sin(2 * pi * chorus_rate * (0:numSamples-1) / fs + lfo_phase(2));

            lfo_phase(1) = mod(lfo_phase(1) + 2 * pi * chorus_rate * numSamples / fs, 2 * pi);
            lfo_phase(2) = mod(lfo_phase(2) + 2 * pi * chorus_rate * numSamples / fs, 2 * pi);
            modulated_delay = zeros(2,numSamples);
            modulated_delay(1,:) = chorus_delay + chorus_depth * lfoL;
            modulated_delay(2,:) = chorus_delay + chorus_depth * lfoR;
            modulated_delay_samples = round(modulated_delay * fs / 1000);
            

            % Process
            out     = zeros(size(in));
            wetRatio = plugin.MixingCoefficient / 100;
            for n = 1 : numSamples
                [out(n,:),er_L,er_R,y_er,in_d,s_ap,y_o,y_d,hfs_ap,hfs_ls,w_idx, chorus_buffer] = FDN_ER(plugin,x(n),numBranches,M,D,L,R,D_p,G_f,er_L,er_R,y_er,in_d,s_ap,y_o,y_d,hfs_ap,hfs_ls,H0_hfs,a_hfs,a_L,a_R,g_erL,g_erR,w_idx,b_sz,chorus_buffer,modulated_delay_samples(:,n),chorus_level);
                out(n,:) = out(n) * db2mag(-24); % this plugin is loud, lets prevent it from being too loud
                out(n,1)        = (1-wetRatio) * in(n,1) + wetRatio * out(n,1); 
                out(n,2)        = (1-wetRatio) * in(n,2) + wetRatio * out(n,2);
            end

            % Update plugin variables from cached variables
            UpdateCache(plugin,D_p,G_f,er_L,er_R,y_er,in_d,s_ap,y_o,y_d,hfs_ap,hfs_ls,w_idx,chorus_buffer,chorus_level*100,lfo_phase);
            % Try to prevent weird things on variable changes
            % (not 100% effective...)
            plugin.storeRSF = plugin.RoomSizeFactor;
            plugin.storeNB = numBranches;
        end

        function [y,er_L,er_R,y_er,in_d,s_ap,y_o,y_d,hfs_ap,hfs_ls,w_idx, chorus_buffer] = FDN_ER(plugin,x,numBranches,M,D,L,R,D_p,G_f,er_L,er_R,y_er,in_d,s_ap,y_o,y_d,hfs_ap,hfs_ls,H0_hfs,a_hfs,a_L,a_R,g_erL,g_erR,w_idx,b_sz,chorus_buffer,modulated_delay_samples, chorus_level)
            % Early Reflections
            for i = 1 : numBranches
                er_L(i,w_idx(4))    = x;
                er_R(i,w_idx(4))    = x;
                idx                 = mod(w_idx(4)-L(i)-1,b_sz(4)) + 1;
                y_er(i,1)           = er_L(i,idx) * g_erL(i);   
                idx                 = mod(w_idx(4)-R(i)-1,b_sz(4)) + 1;
                y_er(i,2)           = er_R(i,idx) * g_erR(i);
            end

            % Feedback Delay Network (FDN)
            % Input to each delay AP - input + feedback (not cascade) from the previous AP
            x_i     = zeros(16,1); 
            y       = zeros(1,2);
            %% TASK 1:
            %%% Task begins here - fill in the required lines of code based
            %%% on the explanation and visual representation from the theory
            %%% slides.
            in_d(w_idx(3)) = x;
            pDelay_idx = mod(w_idx(3) - D_p - 1, b_sz(3)) + 1;
            yL = 0;
            yR = 0;
            hfsout = zeros(numBranches,1);
            readIdx = mod(w_idx(1) - D(i) - 1, b_sz(1)) + 1;
            for i = 1 : numBranches
                if i ~= 1 % grab the last branch's HFS output
                    x_i(i) = in_d(pDelay_idx) + (G_f)^(1/numBranches) * hfsout(i - 1);
                else % grab the previous iteration's last HFS output
                    x_i(i) = in_d(pDelay_idx) + (G_f)^(1/(i - 1)) * hfs_ls;
                end
                [s_ap, y_o] = SchroederAllPass(plugin,x_i(i),M(i),i,s_ap,y_o,w_idx,b_sz);
                [hfsout(i), hfs_ap(i)] = HighFrequencyShelving(plugin,  y_d(i), hfs_ap(i), H0_hfs, a_hfs);
                % w_idx(1) =  % get new index
                y_d(i) = y_o(i, readIdx); % delay the output of apf
                yL = yL + y_d(i) * a_L(i); % use coefficients here, inside of for loop
                yR = yR + y_d(i) * a_R(i); 
            end
            hfs_ls = hfsout(numBranches); % store the last sample of the shelving filter for the next loop


            % Update writeindex
            %% TASK 2:
            %%% Fill in the required lines of code
            % update indices
            w_idx(1)        = mod(w_idx(1),b_sz(1)) + 1;
            w_idx(2)        = mod(w_idx(2),b_sz(2)) + 1;
            w_idx(3)        = mod(w_idx(3),b_sz(3)) + 1;
            w_idx(4)        = mod(w_idx(4),b_sz(4)) + 1;

            % Sum ER branches before chorus
            reflectionsL = 2 * sum(y_er(1:numBranches,1));
            reflectionsR = 2 * sum(y_er(1:numBranches,2));

            if strcmp(plugin.ToggleChorus, 'On')
                % Apply chorus left
                delay_samples = modulated_delay_samples(1);
                delay_idx = mod(w_idx(5) - delay_samples - 1, b_sz(5)) + 1;
                delayed_sample = chorus_buffer(1,delay_idx);
                chorus_buffer(1, w_idx(5)) = reflectionsL;
                w_idx(5) = mod(w_idx(5), b_sz(5)) + 1;
                reflectionsL = delayed_sample * chorus_level + reflectionsL * (1 - chorus_level);
    
                % Apply chorus right
                delay_samples = modulated_delay_samples(2);
                delay_idx = mod(w_idx(6) - delay_samples - 1, b_sz(5)) + 1;
                delayed_sample = chorus_buffer(2,delay_idx);
                chorus_buffer(2, w_idx(6)) = reflectionsR;
                w_idx(6) = mod(w_idx(6), b_sz(5)) + 1;
                reflectionsR = delayed_sample * chorus_level + reflectionsR * (1 - chorus_level);
            end
            % add ER to Diffuse sound
            y(1,1)          = reflectionsL + yL;
            y(1,2)          = reflectionsR + yR;
        end

        % Schroeder Allpass
        function [s_ap,y_o] = SchroederAllPass(plugin,x,M_i,i,s_ap,y_o,w_idx,b_sz)
            idx                 = mod(w_idx(2)-M_i-1,b_sz(2)) + 1;
            x_temp              = s_ap(i,idx);
            % Difference Equation
            s_ap(i,w_idx(2))    = x + plugin.AllPassGain * x_temp;
            y_o(i,w_idx(1))     = x_temp - plugin.AllPassGain * s_ap(i,w_idx(2));
        end

        % High-Frequency Shelving Filter
        function [y,hfs_ap] = HighFrequencyShelving(plugin, x, hfs_ap, H0, a)
            s_h         = x + a * hfs_ap;
            y_ap        = hfs_ap - a * s_h;
            hfs_ap      = s_h;
            y           = 0.5 * H0 * (x - y_ap) + x;
        end
        % Update Plugin Variables from Cached Variables
        function [] = UpdateCache(plugin,D_p,G_f,er_L,er_R,y_er,in_d,s_ap,y_o,y_d,hfs_ap,hfs_ls,w_idx,chorus_buffer, chorus_level,lfo_phase)
                plugin.PreDelay     = D_p;
                plugin.FeedbackGain = G_f;
                plugin.er_L         = er_L;
                plugin.er_R         = er_R;
                plugin.y_er         = y_er;
                plugin.in_d         = in_d;
                plugin.s_ap         = s_ap;
                plugin.y_o          = y_o;
                plugin.y_d          = y_d;
                plugin.hfs_ap       = hfs_ap;       
                plugin.hfs_ls        = hfs_ls;
                plugin.w_yo         = w_idx(1);
                plugin.w_sap        = w_idx(2);
                plugin.w_ind        = w_idx(3);
                plugin.w_er         = w_idx(4);
                plugin.chorus_buffer = chorus_buffer;
                plugin.chorus_idxL = w_idx(5);
                plugin.chorus_idxR = w_idx(6);
                plugin.ChorusLevel = chorus_level;
                plugin.lfo_phase = lfo_phase;
                plugin.roomFactorHasChanged = false;
        end

        % Load Cached Variables
        function [D_p,G_f,er_L,er_R,y_er,in_d,s_ap,y_o,y_d,hfs_ap,hfs_ls,a_L,a_R,g_erL,g_erR,w_idx,b_sz,chorus_buffer,chorus_level,lfo_phase] = LoadCache(plugin)
            D_p         = plugin.PreDelay;
            G_f          = plugin.FeedbackGain;
            er_L        = plugin.er_L;
            er_R        = plugin.er_R;
            y_er        = plugin.y_er;
            in_d        = plugin.in_d;
            s_ap        = plugin.s_ap;
            y_o         = plugin.y_o;
            y_d         = plugin.y_d;
            hfs_ap      = plugin.hfs_ap;     
            hfs_ls       = plugin.hfs_ls;
            a_L         = plugin.a_L * db2mag(plugin.DiffusionGain); % scale coefficients by dB values
            a_R         = plugin.a_R  * db2mag(plugin.DiffusionGain);
            g_erL       = plugin.g_erL * db2mag(plugin.EarlyRefGain);
            g_erR       = plugin.g_erR * db2mag(plugin.EarlyRefGain);
            w_idx       = [plugin.w_yo, plugin.w_sap, plugin.w_ind, plugin.w_er, plugin.chorus_idxL, plugin.chorus_idxR];
            chorus_buffer = plugin.chorus_buffer;
            chorus_level = plugin.ChorusLevel;
            b_sz        = [size(y_o,2), size(s_ap,2), size(in_d,2), size(er_L,2), size(chorus_buffer, 2)];
            lfo_phase = plugin.lfo_phase;
        end

        % Reset
        function reset(plugin)
            % Reset non-tunable properties
            plugin.er_L         = zeros(16,4096);       
            plugin.er_R         = zeros(16,4096);       
            plugin.y_er         = zeros(16,2);          
            plugin.in_d         = zeros(1,4096);        
            plugin.s_ap         = zeros(16,4096);       
            plugin.y_o          = zeros(16,4096);       
            plugin.y_d          = zeros(16,1);  
            plugin.hfs_ap       = zeros(16,1);      
            plugin.chorus_buffer = zeros(2,4096);
            plugin.lfo_phase = zeros(2,1);
            plugin.chorus_idxL = 1;
            plugin.chorus_idxR = 1;
            plugin.w_sap        = 1;                    
            plugin.w_yo         = 1;                    
            plugin.w_ind        = 1;                    
            plugin.w_er         = 1;    
            plugin.roomFactorHasChanged = false;
        end
        function set.RoomSizeFactor(plugin,val)
            plugin.RoomSizeFactor = val;
            plugin.roomFactorHasChanged = true;
        end
        function set.NumberOfBranches(plugin,val)
            plugin.NumberOfBranches = val;
        end
    end
end
