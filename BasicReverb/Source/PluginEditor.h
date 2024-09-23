/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>
#include "PluginProcessor.h"

//==============================================================================
/**
*/
class TestProjectAudioProcessorEditor  : public juce::AudioProcessorEditor, public juce::Slider::Listener, public juce::Button::Listener
{
public:
    TestProjectAudioProcessorEditor (TestProjectAudioProcessor&);
    ~TestProjectAudioProcessorEditor() override;

    //==============================================================================
    void paint (juce::Graphics&) override;
    void resized() override;

private:

    void sliderValueChanged(juce::Slider* slider) override;
    void buttonClicked(juce::Button* button) override;

    TestProjectAudioProcessor& audioProcessor;

    juce::Slider roomSizeKnob;
    juce::Slider dampingKnob;
    juce::Slider wetLevelKnob;
    juce::Slider dryLevelKnob;
    juce::Slider widthKnob;
    juce::ToggleButton freezeButton;

    //===================================================

    using APVTS = juce::AudioProcessorValueTreeState;
    using SliderAttachment = APVTS::SliderAttachment;
    using ButtonAttachment = APVTS::ButtonAttachment;

SliderAttachment roomSizeAttachment
    {
        audioProcessor.apvts,
        myParameterID::r_size.getParamID(),
        roomSizeKnob
    };

    SliderAttachment dampingAttachment
    {
        audioProcessor.apvts,
        myParameterID::r_damping.getParamID(),
        dampingKnob
    };


    SliderAttachment wetLevelAttachment
    {
        audioProcessor.apvts,
        myParameterID::r_wet.getParamID(),
        wetLevelKnob
    };


    SliderAttachment dryLevelAttachment
    {
        audioProcessor.apvts,
        myParameterID::r_dry.getParamID(),
        dryLevelKnob
    };

    SliderAttachment widthAttachment
    {
        audioProcessor.apvts,
        myParameterID::r_width.getParamID(),
        widthKnob
    };

   ButtonAttachment freezeAttachment
   {
       audioProcessor.apvts,
       myParameterID::r_freeze.getParamID(),
       freezeButton
   };
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (TestProjectAudioProcessorEditor)
};
