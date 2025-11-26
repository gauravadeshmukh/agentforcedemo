public class AccountTriggerHandler {
    
    public static void handleTrigger(List<Account> newAccounts, List<Account> oldAccounts) {
        // Process each new account
        for(Account acc : newAccounts) {
            // Check if Account Type is empty or null
            if(String.isBlank(acc.Type)) {
                // Set Account Type to "Partner" 
                acc.Type = 'Partner';
            }
        }
        
        for(integer i=0; i<102; i++){
            Account acc = [Select Id from Account];
        }
    }
}