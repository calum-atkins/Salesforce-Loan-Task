public with sharing class TriggerUtil {
    public static Boolean shouldTriggerRun(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            System.debug('TriggerUtil: Provided object API name is null or blank.');
            return true;
        }

        try {
            // Remove '__c' suffix
            String trimmedName = objectApiName.endsWith('__c') 
                ? objectApiName.replaceAll('__c$', '') 
                : objectApiName;

            // Remove all underscores
            String cleanedName = trimmedName.replaceAll('_', '');

            List<Trigger_Skipper__mdt> skippers = [
                SELECT Active__c 
                FROM Trigger_Skipper__mdt 
                WHERE DeveloperName = :cleanedName
                LIMIT 1
            ];

            if (!skippers.isEmpty()) {
                Boolean isActive = skippers[0].Active__c;
                return !isActive; // If active = true, then skip, so return false
            }

        } catch (Exception ex) {
            System.debug('TriggerUtil: Exception occurred while checking trigger skip logic: ' + ex.getMessage());
        }

        return true; // Default to true (run) if no metadata
    }
}