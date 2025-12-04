trigger AccountTrigger on Account (before insert, before update) {
    Integer recordCount = Trigger.new.size();
    AccountTriggerHandler.handleTrigger(Trigger.new, Trigger.old);

}