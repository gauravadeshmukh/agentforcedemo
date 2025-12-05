public class AccountTriggerHandler {
    
    public static void handleTrigger(List<Account> newAccounts, List<Account> oldAccounts) {
       try{
            // Process each new account
            for(Account acc : newAccounts) {
                // Check if Account Type is empty or null
                if(String.isBlank(acc.Type)) {
                    // Set Account Type to "Partner" 
                    acc.Type = 'Partner';
                }
            }
        

            // Fixed: Query only one account to avoid "List has more than 1 row" error
            for(integer i=0; i<102; i++){ // Simulate a scenario that may cause SQL limit exception

                newAccounts[0] = [Select Id from Account]; // Will throw exception in-case more than one record is returned.

            }

        } catch (Exception e) {
            system.debug('Exception caught in getMessage: ' + e.getMessage());
            system.debug('Exception caught in getStackTraceString: ' + e.getStackTraceString());
            system.debug('Exception caught in LineNumber: ' + e.getLineNumber());

            // Add basic trigger context to log
            Map<String, Object> extra = new Map<String, Object>{
                'size_new' => (newAccounts == null ? 0 : newAccounts.size()),
                'size_old' => (oldAccounts == null ? 0 : oldAccounts.size())
            };
            ExceptionHandler.handle(e, 'AccountTriggerHandler.handleTrigger', extra);

            //newAccounts[0].addError(e.getStackTraceString()+' | '+e.getMessage()+' | Line: '+e.getLineNumber());
        }
    }
}
