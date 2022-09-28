/**
 * Created by Jan Markočič on 21/04/2022.
 */

@RestResource(urlMapping='/Contacts/*')
global with sharing class ContactsWS
{
    private static List<ContactsWSHelper.ErrorMessage> outboundErrors = new List<ContactsWSHelper.ErrorMessage>();

    /**
     * @description Data Warehouse calls this WS to insert a Contact record with a related list of Skills.
     * @task: JMARK-123
     *
     * @param firstName     Contact's first name
     * @param lastName      Contact's last name
     * @param email         Contact's email
     * @param skills        List of SkillW objects representing the contact's skills
     *
     * @return              On success: Id of the inserted Contact record; On error: A list of detected errors;
     */
    @HttpPost
    global static String createContact(String firstName, String lastName, String email, List<ContactsWSHelper.SkillW> skills)
    {
        String response;
        Savepoint sp = Database.setSavepoint();

        try {
            // Validate input
            List<String> badInput = ContactsWSHelper.getInvalidInput(firstName, lastName, email, skills);
            if (badInput.isEmpty()) {
                // Create a Contact record
                Id contactId = ContactsWSHelper.createContact(firstName, lastName, email);

                // Create a related list of Skill records
                Boolean skillsCreatedSuccessfully = ContactsWSHelper.createSkills(contactId, skills);
                if (skillsCreatedSuccessfully == false) {
                    // Catch detected irregularities
                    outboundErrors.add(ContactsWSHelper.ERROR_BAD_SKILL_RATING);
                }
                else {
                    // Handle response
                    response = ContactsWSHelper.formatSuccess(String.valueOf(contactId));
                }
            }
            else {
                outboundErrors.add(ContactsWSHelper.ERROR_BAD_REQUEST.appendMessage(ContactsWSHelper.formatBadInput(badInput)));
            }
        }
        catch (DMLException e) {
            String message = ' '+e.getMessage()+'; '+e.getStackTraceString();
            outboundErrors.add(ContactsWSHelper.ERROR_DML.appendMessage(message));
            Database.rollback(sp);
        }
        catch (Exception e) {
            // Handle unpredicted error
            String message = ' '+e.getMessage()+'; '+e.getStackTraceString();
            outboundErrors.add(ContactsWSHelper.ERROR_INTERNAL.appendMessage(message));
            Database.rollback(sp);
        }

        // Handle response
        if (outboundErrors.isEmpty() == false) {
            response = ContactsWSHelper.formatErrors(outboundErrors);
        }

        // Handle system status response
        if (RestContext.response!=null) {
            RestContext.response.statusCode = ContactsWSHelper.getWorstStatusCode(outboundErrors);
        }

        return response;
    }

}