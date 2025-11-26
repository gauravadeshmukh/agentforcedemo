public class ContactTriggerHandler {
    
    public static void handleTrigger(List<Contact> newContacts, List<Contact> oldContacts) {
        // Process each new contact
        for(Contact con : newContacts) {
            // Check if Lead Source is empty or null
            if(String.isBlank(con.LeadSource)) {
                // Set Lead Source to "Web" 
                con.LeadSource = 'Web';
            }
        }
    }
}
