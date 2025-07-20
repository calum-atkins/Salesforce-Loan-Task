@isTest
public class LoanTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Insert a Person Account
        Account acc = new Account(FirstName = 'Test', LastName = 'Person', RecordTypeId = getPersonAccountRecordTypeId());
        insert acc;

        // Insert a valid Loan with term
        Loan__c loan = new Loan__c(
            Name = 'Valid Loan',
            Account__c = acc.Id,
            Address__Street__s = '123 Loan St',
            Gross_Loan_Amount__c = 10000,
            Date_Loan_Issued__c = Date.today(),
            Term__c = 12
        );
        insert loan;
    }

    @isTest
    static void createNewLoanCharges_validLoan_createsReleaseCharge() {
        // Given
        Loan__c loan = [SELECT Id FROM Loan__c WHERE Name = 'Valid Loan' LIMIT 1];

        // When
        List<Loan_Charge__c> charges = [
            SELECT Id, Charge_Type__c, Amount__c, Loan__c
            FROM Loan_Charge__c
            WHERE Loan__c = :loan.Id
        ];

        // Then
        System.assertEquals(1, charges.size(), 'A Release Charge should be created.');
        System.assertEquals('Release Charge', charges[0].Charge_Type__c);
        System.assertEquals(500, charges[0].Amount__c);
    }

    @isTest
    static void createNewLoanCharges_duplicateLoan_noAdditionalReleaseCharge() {
        // Given
        Loan__c loan = [SELECT Id, Account__c FROM Loan__c WHERE Name = 'Valid Loan' LIMIT 1];

        // When
        Loan__c newLoan = new Loan__c(
            Name = 'Second Loan',
            Account__c = loan.Account__c,
            Address__Street__s = '123 Second St',
            Gross_Loan_Amount__c = 8000,
            Date_Loan_Issued__c = Date.today(),
            Term__c = 6
        );
        insert newLoan;

        // Then
        List<Loan_Charge__c> releaseCharges = [
            SELECT Id FROM Loan_Charge__c WHERE Charge_Type__c = 'Release Charge'
        ];
        System.assertEquals(2, releaseCharges.size(), 'Each Loan should have one Release Charge only.');
    }

    @isTest
    static void createNewLoanCharges_missingDateOrTerm_skipsChargeCreation() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Loan__c loan = new Loan__c(
            Name = 'Missing Info Loan',
            Account__c = acc.Id,
            Gross_Loan_Amount__c = 9000
        );
        insert loan;

        // When
        List<Loan_Charge__c> charges = [
            SELECT Id FROM Loan_Charge__c WHERE Loan__c = :loan.Id
        ];

        // Then
        System.assertEquals(0, charges.size(), 'No Release Charge should be created if Loan_Issue_Date__c or Term__c is null.');
    }

    @isTest
    static void createNewLoanCharges_invalidTerm_noCrash() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Loan__c loan = new Loan__c(
            Name = 'Bad Term Loan',
            Account__c = acc.Id,
            Gross_Loan_Amount__c = 9500,
            Date_Loan_Issued__c = Date.today(),
            Term__c = null
        );
        insert loan;

        // Then
        List<Loan_Charge__c> charges = [SELECT Id FROM Loan_Charge__c WHERE Loan__c = :loan.Id];
        System.assertEquals(0, charges.size(), 'No Release Charge should be created if Term__c is invalid or null.');
    }

    // -- Helpers --
    
    // Get RecordTypeId for Person Account
    private static Id getPersonAccountRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1].Id;
    }
}
