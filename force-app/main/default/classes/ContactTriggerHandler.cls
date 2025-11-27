public class ContactTriggerHandler {
    
    public static void handleTrigger(List<Contact> newContacts, List<Contact> oldContacts) {
        try {
            // Process each new contact
            for (Contact con : newContacts) {
                // Check if Lead Source is empty or null
                if (String.isBlank(con.LeadSource)) {
                    // Set Lead Source to "Web" 
                    con.LeadSource = 'Web';
                }
            }
        } catch (Exception e) {
            // Add basic trigger context to log
            Map<String, Object> extra = new Map<String, Object>{
                'size_new' => (newContacts == null ? 0 : newContacts.size()),
                'size_old' => (oldContacts == null ? 0 : oldContacts.size())
            };
            ExceptionHandler.handle(e, 'ContactTriggerHandler.handleTrigger', extra, true);
        }
    }
}
