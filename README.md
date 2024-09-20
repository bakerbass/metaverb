Author: Ryan Baker
Email: ryanbakermusic@outlook.com
Date: June 15th, 2024
Website: ryanbakermusic.tech
AES MATLAB Hackathon

- [ ] Make a basic juce reverb plugin
  - [ ] https://docs.juce.com/master/classdsp_1_1Reverb.html#details
  - [ ] https://docs.juce.com/master/structReverb_1_1Parameters.html#add75191e7a163d95cd807cbc72fa192c
- [ ] Calibrate diffusion parameters to a reverb time
  - [ ] neural net?
  - [ ] Researching how new tools can be used for this old problem
  - [ ] Using 1 inputs to 3 output (decay time - > allpass, feedback, number of feedback branches)
- [ ] Research
  - [ ] Related works
  - [ ] Draft lit review, methods
  - [ ] Defining experimental design
- [ ] Design user interface
  - [ ] user survey for UX
  - [ ] 11 ish knobs?

- [ ] Porting matlab DSP code
    - [ ] one .h and/or .cpp file per block diagram function
      - [ ] filter.h
        - [ ] comb.h
        - [ ] allpass.h
        - [ ] highshelf.h
      - [ ] delayNetwork.h
        - [ ] branch.h
      - [ ] earlyReflections.h
      - [ ] chorus.h
        - [ ] lfo.h
The included plugin is my submission for the AES MATLAB Hackathon for the Europe 2024 conference. 
The source Matlab file is titled FDN.m
This reverb plugin features spinning reflections via a chorus effect, 
controllable gain for reflections and diffusions to further dial in the desired reverb time, 
and a widener effect which changes the difference between the left and right reflection delays.

My primary source for this Hackathon was the included materials, as well as DAFX (2002) and Freeverb.

While the plugin functions well, do be cautious when changing room size factor and number of branches. 
Despite my efforts, some artifacts can occur when changing these parameters. 
Changing back and forth can mitigate these artifacts.

Responses for addtl tasks:
Evaluate settings for a Small Room, Small Hall, Large Hall, Stadium (and document them using a screen shot of the GUI).
The settings for these types of rooms are included in screenshots of the GUI, found in the folder:
/Plots and Presets/Presets
Presets were dialed in using the electronic drum wave provided


For the following tasks, screen shots of both the GUI and plots of the impulse response measurements
can be found in the folder /Plots and Presets
Check and evaluate alternative settings for the delays M, D, L, R. What is your recommendation?

I decided to leave M and D as they were. I thought the diffuse delays sounded great already.

I decided to change L and R by adding a Wideness parameter, which adds an offset to the right channel
delays. This offset adds perceived wideness to the sound of the early reflections.
The inspiration from this comes from Freeverb:
https://ccrma.stanford.edu/~jos/pasp/Freeverb.html

Check and evaluate alternative settings for the Gain Factors for Left and Right Channel (and document them using a screen shot of the GUI). What is your recommendation?
I found that adding up to 9dB of gain would increase the reverb time significantly, 
while giving the user further control for the diffuse sound. 

Check and evaluate alternative settings for the Gain Factors for Left and Right Early Reflections (and document them using a screen shot of the GUI). What is your recommendation?
Similarly, adding 9dB of gain to the early reflections changes the initial decay of the reverb.
The plots show that it alters the initial decay of the reverb. 
A user looking for a short but punchy snare reverb might add anywhere from 3-9dB 
of early reflection gain, while reducing other parameters to mitigate any unwanted tail.
