# Fade Transition State Diagram

## State Transition Overview

```mermaid
stateDiagram-v2
    [*] --> Normal: Initial
    
    Normal --> FadingOut: setActive/setState called
    FadingOut --> StateChanging: fadeOutCounter == 0
    StateChanging --> FadingIn: State changed, fadeIn started
    FadingIn --> Normal: fadeInCounter >= FADE_SAMPLE_NUM
    
    note right of FadingOut
        _isFadingOut = YES
        _fadeOutCounter: 50 → 0
        Current state processing
        with fade out applied
    end note
    
    note right of StateChanging
        _state = _targetState
        Initialize new state
        _isFadingOut = NO
        _isFadingIn = YES
    end note
    
    note right of FadingIn
        _isFadingIn = YES
        _fadeInCounter: 0 → 50
        New state processing
        with fade in applied
    end note
```

## Variable Value Transitions

### Activation Flow (NONE → REFRAINING)

```mermaid
sequenceDiagram
    participant Setter as setActive()/startRefrain()
    participant State as _state
    participant Target as _targetState
    participant FadeOut as _isFadingOut
    participant FadeIn as _isFadingIn
    participant CounterOut as _fadeOutCounter
    participant CounterIn as _fadeInCounter
    participant Process as processLeft()
    
    Setter->>Target: _targetState = REFRAINING
    Setter->>FadeOut: _isFadingOut = YES
    Setter->>CounterOut: _fadeOutCounter = 50
    
    loop Each processLeft() call during fade out
        Process->>CounterOut: _fadeOutCounter--
        Process->>Process: Apply fade out to samples
        alt fadeOutCounter == 0
            Process->>State: _state = _targetState
            Process->>Process: Initialize new state
            Process->>FadeOut: _isFadingOut = NO
            Process->>FadeIn: _isFadingIn = YES
            Process->>CounterIn: _fadeInCounter = 0
        end
    end
    
    loop Each processLeft() call during fade in
        Process->>CounterIn: _fadeInCounter++
        Process->>Process: Apply fade in to samples
        alt fadeInCounter >= 50
            Process->>FadeIn: _isFadingIn = NO
        end
    end
```

### Deactivation Flow (REFRAINING → NONE)

```mermaid
sequenceDiagram
    participant Setter as exit()/setActive(NO)
    participant State as _state
    participant Target as _targetState
    participant FadeOut as _isFadingOut
    participant FadeIn as _isFadingIn
    participant CounterOut as _fadeOutCounter
    participant CounterIn as _fadeInCounter
    participant Process as processLeft()
    
    Setter->>Target: _targetState = NONE
    Setter->>FadeOut: _isFadingOut = YES
    Setter->>CounterOut: _fadeOutCounter = 50
    
    loop Each processLeft() call during fade out
        Process->>CounterOut: _fadeOutCounter--
        Process->>Process: Apply fade out to samples
        alt fadeOutCounter == 0
            Process->>State: _state = _targetState
            Process->>Process: Reset/cleanup
            Process->>FadeOut: _isFadingOut = NO
            Process->>FadeIn: _isFadingIn = YES
            Process->>CounterIn: _fadeInCounter = 0
        end
    end
    
    loop Each processLeft() call during fade in
        Process->>CounterIn: _fadeInCounter++
        Process->>Process: Apply fade in to samples
        alt fadeInCounter >= 50
            Process->>FadeIn: _isFadingIn = NO
        end
    end
```

## Variable Value Transition Table

### Activation (NONE → REFRAINING)

```mermaid
gantt
    title Variable Values During Activation
    dateFormat X
    axisFormat %s
    
    section State
    _state = NONE           :0, 1
    _state = REFRAINING     :1, 100
    
    section Target
    _targetState = REFRAINING :0, 100
    
    section Flags
    _isFadingOut = YES      :0, 1
    _isFadingOut = NO       :1, 100
    _isFadingIn = YES       :1, 2
    _isFadingIn = NO        :2, 100
    
    section Counters
    _fadeOutCounter: 50→0   :0, 1
    _fadeInCounter: 0→50    :1, 2
```

## Process Flow Diagram

```mermaid
flowchart TD
    Start([processLeft called]) --> CheckFadeOut{_isFadingOut?}
    
    CheckFadeOut -->|YES| ProcessFadeOut[Process current state<br/>Apply fade out]
    ProcessFadeOut --> DecrementCounter[_fadeOutCounter--]
    DecrementCounter --> CheckCounterZero{_fadeOutCounter == 0?}
    
    CheckCounterZero -->|NO| Return1[Return]
    CheckCounterZero -->|YES| ChangeState[_state = _targetState]
    ChangeState --> Initialize[Initialize new state]
    Initialize --> StartFadeIn[_isFadingOut = NO<br/>_isFadingIn = YES<br/>_fadeInCounter = 0]
    StartFadeIn --> ProcessRemaining[Process remaining samples<br/>with fade in]
    ProcessRemaining --> Return1
    
    CheckFadeOut -->|NO| ProcessNormal[Process current state]
    ProcessNormal --> CheckFadeIn{_isFadingIn?}
    
    CheckFadeIn -->|YES| ApplyFadeIn[Apply fade in]
    ApplyFadeIn --> IncrementCounter[_fadeInCounter += numSamples]
    IncrementCounter --> CheckCounterMax{_fadeInCounter >= 50?}
    CheckCounterMax -->|YES| StopFadeIn[_isFadingIn = NO]
    CheckCounterMax -->|NO| Return2[Return]
    StopFadeIn --> Return2
    
    CheckFadeIn -->|NO| Return2
    
    style ChangeState fill:#ff9999
    style Initialize fill:#ffcc99
    style StartFadeIn fill:#99ff99
```

## State Machine Detail

```mermaid
stateDiagram-v2
    [*] --> StateNone: Initial
    
    StateNone --> FadingOutToActive: startRefrain() called
    FadingOutToActive --> StateChangingToActive: fadeOutCounter == 0
    StateChangingToActive --> FadingInToActive: State = REFRAINING<br/>Initialize<br/>Start fade in
    FadingInToActive --> StateRefraining: fadeInCounter >= 50
    
    StateRefraining --> FadingOutToInactive: exit() called
    FadingOutToInactive --> StateChangingToInactive: fadeOutCounter == 0
    StateChangingToInactive --> FadingInToInactive: State = NONE<br/>Reset<br/>Start fade in
    FadingInToInactive --> StateNone: fadeInCounter >= 50
    
    note right of FadingOutToActive
        Variables:
        _state = NONE
        _targetState = REFRAINING
        _isFadingOut = YES
        _fadeOutCounter: 50→0
    end note
    
    note right of StateChangingToActive
        Variables:
        _state = REFRAINING (changed)
        _targetState = REFRAINING
        _isFadingOut = NO
        _isFadingIn = YES
        _fadeInCounter = 0
    end note
    
    note right of FadingInToActive
        Variables:
        _state = REFRAINING
        _targetState = REFRAINING
        _isFadingIn = YES
        _fadeInCounter: 0→50
    end note
```

## Variable Timeline

### Activation Timeline

```mermaid
timeline
    title Activation Flow (NONE → REFRAINING)
    
    section Setter Called
        _targetState = REFRAINING
        _isFadingOut = YES
        _fadeOutCounter = 50
    
    section Fade Out
        _state = NONE (unchanged)
        _fadeOutCounter: 50 → 49 → ... → 1 → 0
        Processing with fade out
    
    section State Change
        _state = REFRAINING (changed!)
        _isFadingOut = NO
        _isFadingIn = YES
        _fadeInCounter = 0
        Initialize new state
    
    section Fade In
        _state = REFRAINING
        _fadeInCounter: 0 → 1 → ... → 49 → 50
        Processing with fade in
    
    section Complete
        _isFadingIn = NO
        Normal processing
```

### Deactivation Timeline

```mermaid
timeline
    title Deactivation Flow (REFRAINING → NONE)
    
    section Setter Called
        _targetState = NONE
        _isFadingOut = YES
        _fadeOutCounter = 50
    
    section Fade Out
        _state = REFRAINING (unchanged)
        _fadeOutCounter: 50 → 49 → ... → 1 → 0
        Processing with fade out
    
    section State Change
        _state = NONE (changed!)
        _isFadingOut = NO
        _isFadingIn = YES
        _fadeInCounter = 0
        Reset/cleanup
    
    section Fade In
        _state = NONE
        _fadeInCounter: 0 → 1 → ... → 49 → 50
        Processing with fade in
    
    section Complete
        _isFadingIn = NO
        Normal processing
```

