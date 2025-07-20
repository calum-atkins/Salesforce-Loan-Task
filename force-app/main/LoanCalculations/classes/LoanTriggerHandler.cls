public with sharing class LoanTriggerHandler {
    public static Boolean ignoreTrigger = false;
    private static final String SOBJECT_NAME = 'Loan';
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

    /**
     * Main trigger handler
     */
    public void run() {

        //Ignore trigger
        System.debug('Ignore ' + ignoreTrigger);
        System.debug('TriggerUtil: shouldTriggerRun(' + !TriggerUtil.shouldTriggerRun(SOBJECT_NAME));
        if (ignoreTrigger || TriggerUtil.shouldTriggerRun(SOBJECT_NAME)) {
            return;
        }

        setupChargesMap();

        TriggerWrapper triggerWrapper = new TriggerWrapper(Trigger.old, Trigger.New, Trigger.oldMap, Trigger.newMap);

        if (Trigger.isAfter && Trigger.isInsert) {
            handleAfterInsert(triggerWrapper);
        }

    }

    /**
     * Setup Charges Map for default values
     */
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

    /**
     * Handle Loan__c inserts
     */
    private void handleAfterInsert(TriggerWrapper triggerWrapper) {
        createNewLoanCharges(triggerWrapper);
    }

    /**
     * Create new Loan_Charge__c records for the provided Loan__c records.
     */
    private static void createNewLoanCharges(TriggerWrapper triggerWrapper) {
        if (!Schema.getGlobalDescribe().get('Loan_Charge__c').getDescribe().isAccessible()) {
            throw new LoanException('Loan Charge not Accessible');
        }
        // Get all Loan__c Ids from newList
        Set<Id> loanIds = new Set<Id>();
        for (Loan__c loan : triggerWrapper.newList) {
            if (loan.Id != null) {
                loanIds.add(loan.Id);
            }
        }

        if (loanIds.isEmpty()) return;

        // Query existing Release Charges for these loans
        Map<Id, Loan_Charge__c> existingReleaseCharges = getExistingReleaseCharges(loanIds);

        // Create new Loan_Charge__c records
        List<Loan_Charge__c> chargesToInsert = new List<Loan_Charge__c>();

        for (Loan__c loan : triggerWrapper.newList) {
            if (!existingReleaseCharges.containsKey(loan.Id)) {
                if (loan.Date_Loan_Issued__c != null && loan.Term__c != null) {
                    Date chargeDate;
                    try {
                        chargeDate = loan.Date_Loan_Issued__c.addMonths(Integer.valueOf(loan.Term__c));
                    } catch (Exception ex) {
                        System.debug('LoanTriggerHandler: Invalid Term__c value on Loan__c Id: ' + loan.Id + ' - ' + ex.getMessage());
                        continue;
                    }

                    Loan_Charge__c newCharge = new Loan_Charge__c(
                        Loan__c = loan.Id,
                        Charge_Type__c = 'Release Charge',
                        Amount__c = chargesMap.get('Release_Charge'),
                        Charge_Date__c = chargeDate
                    );

                    chargesToInsert.add(newCharge);
                } else {
                    System.debug('LoanTriggerHandler: Skipping Loan__c Id ' + loan.Id + ' due to null Loan_Issue_Date__c or Term__c.');
                }
            }
        }

        // Insert
        if (!chargesToInsert.isEmpty()) {
            try {
                if (Schema.getGlobalDescribe().get('Loan_Charge__c').getDescribe().isCreateable()) {
                    insert chargesToInsert;
                }
            } catch (Exception ex) {
                System.debug('LoanTriggerHandler: Failed to insert Loan_Charge__c records: ' + ex.getMessage());
            }
        }
    }

    /**
     * Get existing Release Charges for the provided Loan Ids
     */
    private static Map<Id, Loan_Charge__c> getExistingReleaseCharges(Set<Id> loanIds) {
        try {
            if (!Schema.getGlobalDescribe().get('Loan_Charge__c').getDescribe().isAccessible()) {
                throw new LoanException('Loan Charge not Accessible');
            }
            Map<Id, Loan_Charge__c> existingReleaseCharges = new Map<Id, Loan_Charge__c>();

            for (Loan_Charge__c charge : [
                SELECT Id, Loan__c
                FROM Loan_Charge__c
                WHERE Loan__c IN :loanIds
                  AND Charge_Type__c = 'Release Charge'
            ]) {
                if (charge.Loan__c != null) {
                    existingReleaseCharges.put(charge.Loan__c, charge);
                }
            }

            return existingReleaseCharges;
        } catch (Exception ex) {
            System.debug('LoanTriggerHandler: Exception while querying existing Release Charges: ' + ex.getMessage());
            return new Map<Id, Loan_Charge__c>();
        }
    }
    
    public class LoanException extends Exception {}
}