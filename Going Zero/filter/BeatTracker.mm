//
//  BeatTracker.m
//  Going Zero
//
//  Created by koji on 2023/08/04.
//  Copyright © 2023 kyab. All rights reserved.
//

#import "BeatTracker.h"

#include <vector>

#include <essentia/algorithmfactory.h>
#include <essentia/streaming/algorithms/vectorinput.h>
#include <essentia/scheduler/network.h>
#include <essentia/pool.h>
#include <essentia/streaming/algorithms/poolstorage.h>


using namespace essentia;

@implementation BeatTracker{
    streaming::Algorithm *_intBeatTracker;
    streaming::VectorInput<Real> _vecInput;
    scheduler::Network *_network;
    std::vector<Real> _audioFragmentVec;
    Pool _pool;
    
    std::vector<Real> _finalTicks;
    float _currentSec;
}

-(id)init{
    self = [super init];
    
    if (!essentia::isInitialized()){
        essentia::init();
    }
    
    streaming::AlgorithmFactory &factory = streaming::AlgorithmFactory::instance();
    _intBeatTracker = factory.create("BeatTrackerMultiFeature");
    _vecInput.setVector(&_audioFragmentVec);
    
    _vecInput >> _intBeatTracker->input("signal");
    _intBeatTracker->output("ticks") >> PC(_pool, "rhythm,ticks");
    _intBeatTracker->output("confidence") >> streaming::NOWHERE;
    
    _network = new scheduler::Network(&_vecInput);
    _network->runPrepare();
    
    _currentSec = 0;
    
    return self;
}

-(float)pastBeatTime{
    return 0;
}

-(float)estimatedNextBeatTime{
    return 0.6;
}

-(void)processLeft:(float *)leftBuf right:(float *)rightBuf samples:(UInt32)numSamples{
    _currentSec += numSamples/44100.0f;
}

@end
