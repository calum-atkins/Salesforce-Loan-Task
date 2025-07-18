trigger LoanTrigger on Loan__c (after insert, after update) {
    LoanTriggerHandler triggerHandler = new LoanTriggerHandler();
    triggerHandler.run();
}