/*
  ==============================================================================

    ParameterHandler.h
    Created: 11 Dec 2023 11:27:07am
    Author:  Ryan Baker

  ==============================================================================
*/

#pragma once
#include <JuceHeader.h>

template<typename T>
inline static void castParameter(juce::AudioProcessorValueTreeState& apvts,
                                 const juce::ParameterID& id, T& destination)
{
    destination = dynamic_cast<T>(apvts.getParameter(id.getParamID())); jassert(destination); // parameter does not exist or wrong type
}
