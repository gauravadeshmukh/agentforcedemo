@isTest
public class ContactTriggerHandlerTest {
    
    @isTest
    static void testHandleTriggerWithEmptyLeadSource() {
        // Create a contact with empty Lead Source
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            LeadSource = '' // Empty Lead Source
        );
        
        List<Contact> contacts = new List<Contact>{con};
        
        // Call the handler method
        ContactTriggerHandler.handleTrigger(contacts, new List<Contact>());
        
        // Verify that Lead Source was updated to Web
        System.assertEquals('Web', con.LeadSource, 'Lead Source should be set to Web');
    }
    
    @isTest
    static void testHandleTriggerWithNullLeadSource() {
        // Create a contact with null Lead Source
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            LeadSource = null // Null Lead Source
        );
        
        List<Contact> contacts = new List<Contact>{con};
        
        // Call the handler method
        ContactTriggerHandler.handleTrigger(contacts, new List<Contact>());
        
        // Verify that Lead Source was updated to Web
        System.assertEquals('Web', con.LeadSource, 'Lead Source should be set to Web');
    }
    
    @isTest
    static void testHandleTriggerWithLeadSourceAlreadySet() {
        // Create a contact with Lead Source already set
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            LeadSource = 'Email' // Already set Lead Source
        );
        
        List<Contact> contacts = new List<Contact>{con};
        
        // Call the handler method
        ContactTriggerHandler.handleTrigger(contacts, new List<Contact>());
        
        // Verify that Lead Source was not changed
        System.assertEquals('Email', con.LeadSource, 'Lead Source should remain Email');
    }
    
    @isTest
    static void testHandleTriggerWithWhitespaceLeadSource() {
        // Create a contact with whitespace Lead Source
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            LeadSource = '   ' // Whitespace Lead Source
        );
        
        List<Contact> contacts = new List<Contact>{con};
        
        // Call the handler method
        ContactTriggerHandler.handleTrigger(contacts, new List<Contact>());
        
        // Verify that Lead Source was updated to Web (String.isBlank considers whitespace as blank)
        System.assertEquals('Web', con.LeadSource, 'Lead Source should be set to Web');
    }
}
