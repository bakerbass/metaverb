/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>
#include "ParameterHandler.h"

namespace myParameterID {
#define PARAMETER_ID(str) const juce::ParameterID str(#str, 1);
    PARAMETER_ID(r_size)
    PARAMETER_ID(r_damping)
    PARAMETER_ID(r_wet)
    PARAMETER_ID(r_dry)
    PARAMETER_ID(r_width)
    PARAMETER_ID(r_freeze)
    #undef PARAMETER_ID
}
//==============================================================================
/**
*/
class TestProjectAudioProcessor  : public juce::AudioProcessor, private juce::ValueTree::Listener
{
public:
    //==============================================================================
    TestProjectAudioProcessor();
    ~TestProjectAudioProcessor() override;

    //==============================================================================
    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

   #ifndef JucePlugin_PreferredChannelConfigurations
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
   #endif

    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    //==============================================================================
    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    //==============================================================================
    const juce::String getName() const override;

    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    //==============================================================================
    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;

    //==============================================================================
    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;

    juce::AudioProcessorValueTreeState apvts { *this, nullptr, "Parameters", createParameterLayout() };

private:

  juce::Reverb reverb;

    juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();

    void valueTreePropertyChanged(juce::ValueTree&, const juce::Identifier&) override
    {
        parametersChanged.store(true);
    }
    std::atomic<bool> parametersChanged { false };

    void update();

    juce::AudioParameterFloat*  roomSizeParameter;
    juce::AudioParameterFloat*  dampingParameter;
    juce::AudioParameterFloat*  wetLevelParameter;
    juce::AudioParameterFloat*  dryLevelParameter;
    juce::AudioParameterFloat*  widthParameter;
    juce::AudioParameterFloat*  freezeParameter;

    //==============================================================================
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (TestProjectAudioProcessor)
};
