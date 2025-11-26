trigger ContactTrigger on Contact (before insert, before update) {
    ContactTriggerHandler.handleTrigger(Trigger.new, Trigger.old);
}
