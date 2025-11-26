trigger AccountTrigger on Account (before insert, before update) {
    AccountTriggerHandler.handleTrigger(Trigger.new, Trigger.old);
}