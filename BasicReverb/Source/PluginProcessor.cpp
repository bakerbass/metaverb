/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
TestProjectAudioProcessor::TestProjectAudioProcessor()
#ifndef JucePlugin_PreferredChannelConfigurations
     : AudioProcessor (BusesProperties()
                     #if ! JucePlugin_IsMidiEffect
                      #if ! JucePlugin_IsSynth
                       .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                      #endif
                       .withOutput ("Output", juce::AudioChannelSet::stereo(), true)
                     #endif
                       )
#endif
{
    apvts.state.addListener(this);
    
    castParameter(apvts, myParameterID::r_size, roomSizeParameter);
    castParameter(apvts, myParameterID::r_damping, dampingParameter);
    castParameter(apvts, myParameterID::r_wet, wetLevelParameter);
    castParameter(apvts, myParameterID::r_damping, dryLevelParameter);
    castParameter(apvts, myParameterID::r_width, widthParameter);
    castParameter(apvts, myParameterID::r_freeze, freezeParameter);
}

TestProjectAudioProcessor::~TestProjectAudioProcessor()
{
    apvts.state.removeListener(this);
}

//==============================================================================
const juce::String TestProjectAudioProcessor::getName() const
{
    return JucePlugin_Name;
}

bool TestProjectAudioProcessor::acceptsMidi() const
{
   #if JucePlugin_WantsMidiInput
    return true;
   #else
    return false;
   #endif
}

bool TestProjectAudioProcessor::producesMidi() const
{
   #if JucePlugin_ProducesMidiOutput
    return true;
   #else
    return false;
   #endif
}

bool TestProjectAudioProcessor::isMidiEffect() const
{
   #if JucePlugin_IsMidiEffect
    return true;
   #else
    return false;
   #endif
}

double TestProjectAudioProcessor::getTailLengthSeconds() const
{
    return 0.0; // This should change once reverb time is calibrated as a parameter
}

int TestProjectAudioProcessor::getNumPrograms()
{
    return 1;   // NB: some hosts don't cope very well if you tell them there are 0 programs,
                // so this should be at least 1, even if you're not really implementing programs.
}

int TestProjectAudioProcessor::getCurrentProgram()
{
    return 0;
}

void TestProjectAudioProcessor::setCurrentProgram (int index)
{
}

const juce::String TestProjectAudioProcessor::getProgramName (int index)
{
    return {};
}

void TestProjectAudioProcessor::changeProgramName (int index, const juce::String& newName)
{
}

//==============================================================================
void TestProjectAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    parametersChanged.store(true);
    juce::dsp::ProcessSpec spec;
    spec.sampleRate = sampleRate;
    spec.maximumBlockSize = samplesPerBlock;
    spec.numChannels = getTotalNumInputChannels();

    reverb.prepare(spec);
}

void TestProjectAudioProcessor::releaseResources()
{
    // When playback stops, you can use this as an opportunity to free up any
    // spare memory, etc.
}

#ifndef JucePlugin_PreferredChannelConfigurations
bool TestProjectAudioProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
  #if JucePlugin_IsMidiEffect
    juce::ignoreUnused (layouts);
    return true;
  #else
    // This is the place where you check if the layout is supported.
    // In this template code we only support mono or stereo.
    // Some plugin hosts, such as certain GarageBand versions, will only
    // load plugins that support stereo bus layouts.
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
     && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    // This checks if the input layout matches the output layout
   #if ! JucePlugin_IsSynth
    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;
   #endif

    return true;
  #endif
}
#endif

void TestProjectAudioProcessor::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;
    auto totalNumInputChannels  = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    // In case we have more outputs than inputs, this code clears any output
    // channels that didn't contain input data, (because these aren't
    // guaranteed to be empty - they may contain garbage).
    // This is here to avoid people getting screaming feedback
    // when they first compile a plugin, but obviously you don't need to keep
    // this code if your algorithm always overwrites all the output channels.
    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear (i, 0, buffer.getNumSamples());

    bool expected = true;
    if (isNonRealtime() || parametersChanged.compare_exchange_strong(expected, false))
    {
        update();
    }

    juce::dsp::AudioBlock<float> audioBlock(buffer);
    juce::dsp::ProcessContextReplacing<float> context(audioBlock);
    reverb.process(context);
}

//==============================================================================
bool TestProjectAudioProcessor::hasEditor() const
{
    return true; // (change this to false if you choose to not supply an editor)
}

juce::AudioProcessorEditor* TestProjectAudioProcessor::createEditor()
{
    // return new TestProjectAudioProcessorEditor (*this);
    auto editor = new juce::GenericAudioProcessorEditor(*this);
    return editor;
}

//==============================================================================
void TestProjectAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    // You should use this method to store your parameters in the memory block.
    // You could do that either as raw data, or use the XML or ValueTree classes
    // as intermediaries to make it easy to save and load complex data.
}

void TestProjectAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    // You should use this method to restore your parameters from this memory block,
    // whose contents will have been created by the getStateInformation() call.
}

//==============================================================================
// This creates new instances of the plugin..
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new TestProjectAudioProcessor();
}
//==============================================================================
void TestProjectAudioProcessor::update()
{
    juce::dsp::Reverb::Parameters reverbParams;

    reverbParams.roomSize = roomSizeParameter->get();
    reverbParams.damping = dampingParameter->get();
    reverbParams.wetLevel = wetLevelParameter->get();
    reverbParams.dryLevel = dryLevelParameter->get();
    reverbParams.freezeMode = float(freezeParameter->get());
    
    reverb.setParameters(reverbParams);
}
juce::AudioProcessorValueTreeState::ParameterLayout TestProjectAudioProcessor::createParameterLayout()
{
    juce::AudioProcessorValueTreeState::ParameterLayout layout;
    // Parameter Code Goes Here

    layout.add(std::make_unique<juce::AudioParameterFloat>(
        myParameterID::r_size,
        "Room Size",
        juce::NormalisableRange<float>(0.f, 1.f, 0.01f), 0.3f,
        juce::AudioParameterFloatAttributes()));
    layout.add(std::make_unique<juce::AudioParameterFloat>(
        myParameterID::r_damping,
        "Damping",
        juce::NormalisableRange<float>(0.f, 1.f, 0.01f), 0.3f,
        juce::AudioParameterFloatAttributes()));
    layout.add(std::make_unique<juce::AudioParameterFloat>(
        myParameterID::r_wet,
        "Wet Level",
        juce::NormalisableRange<float>(0.f, 1.f, 0.01f), 1.f,
        juce::AudioParameterFloatAttributes()));
    layout.add(std::make_unique<juce::AudioParameterFloat>(
        myParameterID::r_dry,
        "Dry Level",
        juce::NormalisableRange<float>(0.f, 1.f, 0.01f), 0.f,
        juce::AudioParameterFloatAttributes()));
    layout.add(std::make_unique<juce::AudioParameterFloat>(
        myParameterID::r_width,
        "Wideness",
        juce::NormalisableRange<float>(0.f, 1.f, 0.01f), 0.3f,
        juce::AudioParameterFloatAttributes()));
    layout.add(std::make_unique<juce::AudioParameterBool>(
        myParameterID::r_freeze,
        "Freeze",
        false, // Default value for the bool parameter
        juce::AudioParameterBoolAttributes()));

    return layout;
}