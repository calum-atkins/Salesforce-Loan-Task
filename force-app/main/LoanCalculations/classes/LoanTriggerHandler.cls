public with sharing class LoanTriggerHandler {
    public static Boolean ignoreTrigger = false;

    // Wrapper class for trigger values
    private class TriggerWrapper {
        private List<Loan__c> oldList;
        private List<Loan__c> newList;
        private Map<Id, Loan__c> oldMap;
        private Map<Id, Loan__c> newMap;
    
        private TriggerWrapper(List<SObject> oldList, List<SObject> newList, Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
            this.oldList = (List<Loan__c>) oldList;
            this.newList = (List<Loan__c>)newList;
            this.oldMap = (Map<Id, Loan__c>) oldMap;
            this.newMap = (Map<Id, Loan__c>) newMap;
        }
    }

    public void run() {

        //Ignore trigger
        if (ignoreTrigger) {
            return;
        }

        TriggerWrapper triggerWrapper = new TriggerWrapper(Trigger.old, Trigger.New, Trigger.oldMap, Trigger.newMap);

        if (Trigger.isAfter && Trigger.isInsert) {
            handleAfterInsert(triggerWrapper);
        }

    }

    
    private void handleAfterInsert(TriggerWrapper triggerWrapper) {

    }
}