/**
 * @description Trigger for Application_Exception__c object
 * @author Claude
 * @date 2025-11-27
 */
trigger ApplicationExceptionTrigger on Application_Exception__c (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        ApplicationExceptionTriggerHandler.handleAfterInsert(Trigger.new);
    }
}
