public with sharing class LoanTriggerHandler {
    public static Boolean ignoreTrigger = false;
    private static final String SOBJECT_NAME = 'Loan__c';
    private static Map<String, Double> chargesMap = new Map<String, Double>();

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
        if (ignoreTrigger || !TriggerUtil.shouldTriggerRun(SOBJECT_NAME)) {
            return;
        }

        setupChargesMap();

        TriggerWrapper triggerWrapper = new TriggerWrapper(Trigger.old, Trigger.New, Trigger.oldMap, Trigger.newMap);

        if (Trigger.isAfter && Trigger.isInsert) {
            handleAfterInsert(triggerWrapper);
        }

    }

    private static void setupChargesMap() {
        try {
            List<Loan_Amounts__mdt> chargeRecords = [
                SELECT DeveloperName, Value__c
                FROM Loan_Amounts__mdt
            ];
    
            for (Loan_Amounts__mdt record : chargeRecords) {
                if (record != null && record.DeveloperName != null && record.Value__c != null) {
                    chargesMap.put(record.DeveloperName, record.Value__c);
                }
            }
        
        } catch (Exception ex) {
            System.debug('LoanTriggerHandler: Exception in setupChargesMap: ' + ex.getMessage());
        }
    }


    private void handleAfterInsert(TriggerWrapper triggerWrapper) {

    }
}