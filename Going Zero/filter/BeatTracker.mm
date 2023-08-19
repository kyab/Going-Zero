//
//  BeatTracker.m
//  Going Zero
//
//  Created by koji on 2023/08/04.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "BeatTracker.h"

#include <vector>
#include <algorithm>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#pragma clang diagnostic ignored "-Wundefined-var-template"
#pragma clang diagnostic ignored "-Wshorten-64-to-32"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#include <essentia/algorithmfactory.h>
#include <essentia/streaming/algorithms/vectorinput.h>
#include <essentia/scheduler/network.h>
#include <essentia/pool.h>
#include <essentia/streaming/algorithms/poolstorage.h>
#pragma clang diagnostic pop

using namespace essentia;

@implementation BeatTracker{
    streaming::Algorithm *_intBeatTracker;
    streaming::VectorInput<Real> _vecInput;
    scheduler::Network *_network;
    std::vector<Real> _audioFragment;
    std::vector<Real> _audioPool;
    Pool _pool;
    
    std::vector<Real> _finalTicks;
    UInt64 _processedSample;
    UInt64 _currentSample;
    
    dispatch_queue_t _beatTrackerQueue;
    
    Boolean _async_in_progress;
}

-(id)init{
    self = [super init];
    
    if (!essentia::isInitialized()){
        essentia::init();
    }
    
    streaming::AlgorithmFactory &factory = streaming::AlgorithmFactory::instance();
    _intBeatTracker = factory.create("BeatTrackerMultiFeature");
    _vecInput.setVector(&_audioFragment);
    
    _vecInput >> _intBeatTracker->input("signal");
    _intBeatTracker->output("ticks") >> PC(_pool, "rhythm.ticks");
    _intBeatTracker->output("confidence") >> streaming::NOWHERE;
    
    _network = new scheduler::Network(&_vecInput);
    _network->runPrepare();
    
    _processedSample = 0;
    _currentSample = 0;
    
    
    _beatTrackerQueue = dispatch_queue_create("beatTrackerQueue", DISPATCH_QUEUE_SERIAL);
    
    _async_in_progress = false;
    
    return self;
}

-(float)pastBeatRelativeSec{
    
    if (_finalTicks.size() < 4){
        return 0;
    }
    Real sum = 0.0f;
    for (size_t i = _finalTicks.size()-4; i < _finalTicks.size()-1 ; i++){
        sum += _finalTicks[i+1] - _finalTicks[i];
    }
    Real average = sum/3.0f;
    
    Real lastBeatSec = _finalTicks[_finalTicks.size()-1];
    Real previousBeatSec = lastBeatSec;
    while(previousBeatSec + average < _currentSample*(Real)44100.0){
        previousBeatSec += average;
    }
    
    return -1.0*(_currentSample * 44100.0f - previousBeatSec);
    
    
}

-(float)estimatedNextBeatRelativeSec{
    if (_finalTicks.size() < 4){
        return 1.0f;
    }
    Real sum = 0.0f;
    for (size_t i = _finalTicks.size()-4; i < _finalTicks.size()-1 ; i++){
        sum += _finalTicks[i+1] - _finalTicks[i];
    }
    Real average = sum/3.0f;
    
    Real lastBeatSec = _finalTicks[_finalTicks.size()-1];
    Real nextBeatSec = lastBeatSec;
    while(nextBeatSec  < _currentSample*(Real)44100.0){
        nextBeatSec += average;
    }
    
    return nextBeatSec - _currentSample * 44100.0f;
    
}

-(void)printBeats{
    NSLog(@"print %lu beats", _finalTicks.size());
    Real delta = 0.0f;
    for (size_t i = 0 ; i < _finalTicks.size() ; i++){
        if (i > 0){
            delta = _finalTicks[i] - _finalTicks[i-1];
        }
        NSLog(@"beat[%lu] : %f[sec]. delta = %f[sec]", i, _finalTicks[i], delta);
    }
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{

    if (!_async_in_progress){
        
        for (UInt32 i = 0 ; i < numSamples ; i++){
            _audioFragment.push_back((leftBuf[i] + rightBuf[i])/2.0);
        }
                
        if (_processedSample == 0){
            if (_audioFragment.size() >= 5 * 44100){
                
                dispatch_async(_beatTrackerQueue, ^{
                    while(_network->runStep()){
                        ;
                    }
                    
                    NSLog(@"runStep done %f[sec]", _currentSample/44100.0f);
                    if(_pool.contains<std::vector<Real>>("rhythm.ticks")){
                        std::vector<Real> ticks = _pool.value<std::vector<Real>>("rhythm.ticks");
                        for (int i = 0 ; i < ticks.size() ; i++){
                            _finalTicks.push_back(ticks[i]);
                        }
                    }
                    
                    _vecInput.reset();
                    _intBeatTracker->reset();
                    _pool.remove("rhythm.ticks");
                    
                    _processedSample += _audioFragment.size();
                    std::copy(_audioPool.cbegin(), _audioPool.cend(), std::back_inserter(_audioFragment));
                    _audioPool.clear();
                    _async_in_progress = false;
                    [self printBeats];
                });
                _async_in_progress = true;
                NSLog(@"dispatched first %f[sec]", _currentSample/44100.0f );
                
            }
            
        }else{
            if (_audioFragment.size() >= 12 * 44100){
                
                dispatch_async(_beatTrackerQueue, ^{
                    while(_network->runStep()){
                        ;
                    }
                    NSLog(@"runStep done 12 %f[sec]", _currentSample/44100.0f);
                    if(_pool.contains<std::vector<Real>>("rhythm.ticks")){
                        std::vector<Real> ticks = _pool.value<std::vector<Real>>("rhythm.ticks");
                        for (int i = 0 ; i < ticks.size() ; i++){
                            Real tick = ticks[i];
                            if (5.0 <= tick && tick <= 10.0 ){
                                _finalTicks.push_back(_processedSample/44100.0 + tick - 5.0);
                            }
                        }
                    }
                    
                    _vecInput.reset();
                    _intBeatTracker->reset();
                    _pool.remove("rhythm.ticks");
                    
                    std::shift_left(_audioFragment.begin(), _audioFragment.end() ,44100 * 5);
                    _audioFragment.erase(_audioFragment.cbegin()+44100*7, _audioFragment.cend());
                    std::copy(_audioPool.cbegin(), _audioPool.cend(), std::back_inserter(_audioFragment));
                    _audioPool.clear();
                    
                    _processedSample += 44100*5;
                    _async_in_progress = false;

                    [self printBeats];
                    
                });
                _async_in_progress = true;
                NSLog(@"dispatched %f[sec]", _currentSample/44100.0f );
            }
            
        }
    }else{
        for (UInt32 i = 0 ; i < numSamples ; i++){
            _audioPool.push_back((leftBuf[i] + rightBuf[i])/2.0);
        }
    }
    
    _currentSample += numSamples;

}

@end
