A basic reverb plugin created using the [JUCE reverb class](https://docs.juce.com/master/classdsp_1_1Reverb.html#a67582b7d70a6a0f444be8e3649b184b3)
![image](https://github.com/user-attachments/assets/a924bd3e-0d3f-44a1-931f-e9cff09fed89)

## Parameters:
- Room size
- Damping
- Wet Level
- Dry Level
- Width/Wideness
- Freeze Mode
- [JUCE Documentation](https://docs.juce.com/master/structReverb_1_1Parameters.html#add75191e7a163d95cd807cbc72fa192c)
- Note that the freeze parameter is probably not useful for impulse response matching.
## To do:
 - [ ] Implement reverb processing
 - [ ] Implement additional processing e.g. filtering
   - [ ] Parameter and linking
 - [ ] Parameter Work:
   - [x] Implement basic parameter linked GUI
   - [ ] Convert normalized parameters to useful parameters
     - [ ] Wet/Dry levels as dB values (or one percentage value)
     - [ ] Room size to RT60 time values
     - [ ] Damping? This could be left normalized

