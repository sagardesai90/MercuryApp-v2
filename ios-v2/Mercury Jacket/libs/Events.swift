import Foundation

class EventManager {
    // using NSMutableArray as Swift arrays can't change size inside dictionaries (yet, probably)
    var listeners = Dictionary<String, Dictionary<String, NSMutableArray>>();
    
    // Create a new event listener, not expecting information from the trigger
    // + eventName: Matching trigger eventNames will cause this listener to fire
    // + action: The block of code you want executed when the event triggers
    func listenTo(id :String, eventName:String, action: @escaping (()->())) {
        let newListener = EventListenerAction(callback: action);
        addListener(id: id, eventName: eventName, newEventListener: newListener);
    }
    
    // Create a new event listener, expecting information from the trigger
    // + eventName: Matching trigger eventNames will cause this listener to fire
    // + action: The block of code you want executed when the event triggers
    func listenTo(id :String, eventName:String, action: @escaping ((Any?)->())) {
        let newListener = EventListenerAction(callback: action);
        addListener(id: id, eventName: eventName, newEventListener: newListener);
    }
    
    internal func addListener(id :String, eventName:String, newEventListener:EventListenerAction) {
        let dic = self.listeners[id]
        
        if(dic == nil)
        {
            self.listeners[id] = Dictionary<String, NSMutableArray>()
        }
        
        if let listenerArray = self.listeners[id]![eventName] {
            // action array exists for this event, add new action to it
            listenerArray.add(newEventListener);
        }
        else {
            // no listeners created for this event yet, create a new array
            self.listeners[id]![eventName] = [newEventListener] as NSMutableArray;
        }
    }
    
    // Removes all listeners by default, or specific listeners through paramters
    // + eventName: If an event name is passed, only listeners for that event will be removed
    func removeListeners(id :String, eventNameToRemoveOrNil:String?) {
        var dic = self.listeners[id]
        
        if(dic != nil)
        {
            if(eventNameToRemoveOrNil != nil)
            {
                dic?.removeValue(forKey: eventNameToRemoveOrNil!)
            }else{
                self.listeners.removeValue(forKey: id)
            }
        }
    }
    
    // Triggers an event
    // + eventName: Matching listener eventNames will fire when this is called
    // + information: pass values to your listeners
    func trigger(eventName:String, information:Any? = nil) {
        //print("DISPATCH_EVENT; ", eventName, self.listeners.keys);
        for dic in self.listeners {
            if let actionObjects = dic.value[eventName] {
                for actionObject in actionObjects {
                    if let actionToPerform = actionObject as? EventListenerAction {
                        if let methodToCall = actionToPerform.actionExpectsInfo {
                            methodToCall(information);
                        }
                        else if let methodToCall = actionToPerform.action {
                            methodToCall();
                        }
                    }
                }
            }
        }
    }
}

// Class to hold actions to live in NSMutableArray
class EventListenerAction {
    let action:(() -> ())?;
    let actionExpectsInfo:((Any?) -> ())?;
    
    init(callback: @escaping (() -> ()) ) {
        self.action = callback;
        self.actionExpectsInfo = nil;
    }
    
    init(callback: @escaping ((Any?) -> ()) ) {
        self.actionExpectsInfo = callback;
        self.action = nil;
    }
}
