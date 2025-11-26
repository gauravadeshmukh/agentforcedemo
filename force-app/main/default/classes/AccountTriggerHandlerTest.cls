@isTest
public class AccountTriggerHandlerTest {
    
    @isTest
    static void testHandleTriggerWithEmptyType() {
        // Create an account with empty Type
        Account acc = new Account(
            Name = 'Test Account',
            Type = '' // Empty Type
        );
        
        List<Account> accounts = new List<Account>{acc};
        
        // Call the handler method
        AccountTriggerHandler.handleTrigger(accounts, new List<Account>());
        
        // Verify that Type was updated to Partner
        System.assertEquals('Partner', acc.Type, 'Account Type should be set to Partner');
    }
    
    @isTest
    static void testHandleTriggerWithNullType() {
        // Create an account with null Type
        Account acc = new Account(
            Name = 'Test Account',
            Type = null // Null Type
        );
        
        List<Account> accounts = new List<Account>{acc};
        
        // Call the handler method
        AccountTriggerHandler.handleTrigger(accounts, new List<Account>());
        
        // Verify that Type was updated to Partner
        System.assertEquals('Partner', acc.Type, 'Account Type should be set to Partner');
    }
    
    @isTest
    static void testHandleTriggerWithTypeAlreadySet() {
        // Create an account with Type already set
        Account acc = new Account(
            Name = 'Test Account',
            Type = 'Customer' // Already set Type
        );
        
        List<Account> accounts = new List<Account>{acc};
        
        // Call the handler method
        AccountTriggerHandler.handleTrigger(accounts, new List<Account>());
        
        // Verify that Type was not changed
        System.assertEquals('Customer', acc.Type, 'Account Type should remain Customer');
    }
    
    @isTest
    static void testHandleTriggerWithWhitespaceType() {
        // Create an account with whitespace Type
        Account acc = new Account(
            Name = 'Test Account',
            Type = '   ' // Whitespace Type
        );
        
        List<Account> accounts = new List<Account>{acc};
        
        // Call the handler method
        AccountTriggerHandler.handleTrigger(accounts, new List<Account>());
        
        // Verify that Type was updated to Partner (String.isBlank considers whitespace as blank)
        System.assertEquals('Partner', acc.Type, 'Account Type should be set to Partner');
    }
}