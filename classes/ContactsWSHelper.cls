/**
 * Created by Jan Markočič on 21/04/2022.
 */

global with sharing class ContactsWSHelper {
    public static final ErrorMessage ERROR_INTERNAL = new ErrorMessage(
            'ERROR_INTERNAL',
            'Internal Server Error.',
            500);  // An error has occurred within Lightning Platform, so the request couldn’t be completed. Contact Salesforce Customer Support.
    public static final ErrorMessage ERROR_DML = new ErrorMessage(
            'ERROR_DML',
            'An error occurred while inserting a record.',
            500);  // An error has occurred within Lightning Platform, so the request couldn’t be completed. Contact Salesforce Customer Support.
    public static final ErrorMessage ERROR_BAD_REQUEST = new ErrorMessage(
            'ERROR_BAD_REQUEST',
            'Bad input values.',
            415);  // The entity in the request is in a format that’s not supported by the specified method.
    public static final ErrorMessage ERROR_BAD_SKILL_RATING = new ErrorMessage(
            'ERROR_BAD_SKILL_RATING',
            'Skill ratings must have a value between 0 and 100.',
            415);  // The entity in the request is in a format that’s not supported by the specified method.

    private static final String INPUT_FIRST_NAME = 'firstName';
    private static final String INPUT_LAST_NAME = 'lastName';
    private static final String INPUT_EMAIL = 'email';
    private static final String INPUT_SKILLS = 'skills';

    /**
     * @description Check each input and return the names of those with irregularities
     */
    public static List<String> getInvalidInput(String firstName, String lastName, String email, List<SkillW> skills) {
        List<String> invalidInputStrings = new List<String>();

        if (String.isBlank(firstName)) {
            invalidInputStrings.add(INPUT_FIRST_NAME);
        }

        if (String.isBlank(lastName)) {
            invalidInputStrings.add(INPUT_LAST_NAME);
        }

        if (String.isBlank(email)) {
            invalidInputStrings.add(INPUT_EMAIL);
        }

        if (skills == null) {
            invalidInputStrings.add(INPUT_SKILLS);
        }

        return invalidInputStrings;
    }

    /**
     * @description Insert a Contact record and return its Id
     */
    public static Id createContact(String firstName, String lastName, String email) {
        Contact contactRecord = new Contact(
                FirstName = firstName,
                LastName = lastName,
                Email = email
        );

        insert contactRecord;

        return contactRecord.Id;
    }

    /**
     * @description Insert all given Skill records after converting them from their wrapper format
     * @return True if successful, false otherwise
     */
    public static Boolean createSkills(Id contactId, List<SkillW> skills) {
        Boolean success = true;
        List<Skill> skillRecords = new List<Skill>();

        if (skills?.size() > 0) {
            for (SkillW skillWrapper : skills) {
                // Check requirements
                if (skillWrapper.rating < 0 || skillWrapper.rating > 100) {
                    success = false;
                }

                // Create record
                skillRecords.add(new Skill(
                        ContactId = contactId,
                        Name = skillWrapper.name,
                        Rating = skillWrapper.rating
                ));
            }

            insert skillRecords;
        }

        return success;
    }

    /**
     * @description Returns the code of the worst error
     */
    public static Integer getWorstStatusCode(List<ErrorMessage> errorMessages)
    {
        Integer worstStatusCode = 201;
        for (ErrorMessage errorMessage : errorMessages)
        {
            if (errorMessage.statusCode > worstStatusCode) {
                worstStatusCode = errorMessage.statusCode;
            }
        }

        return worstStatusCode;
    }

    /**
     * Utility methods
     */

    public static String formatSuccess(String message) {
        return JSON.serialize(new Response(true, message));
    }

    public static String formatErrors(List<ErrorMessage> errorMessages) {
        return JSON.serialize(new Response(false, errorMessages));
    }

    public static String formatBadInput(List<String> inputNames) {
        return ' ('+String.join(inputNames, ', ')+')';
    }

    /**
     * Wrappers
     */

    global class SkillW {
        public String name;
        public Integer rating;
    }

    private class Response {
        public Boolean success;
        public String message;
        public List<ErrorMessage> errorMessages;

        public Response(Boolean success, String message) {
            this.success = success;
            this.message = message;
        }

        public Response(Boolean success, List<ErrorMessage> errorMessages) {
            this.success = success;
            this.errorMessages = errorMessages;
        }
    }

    public class ErrorMessage {
        public Integer statusCode;  // https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/errorcodes.htm
        public String errorCode;
        public String message;
        public ErrorMessage(String errorCode, String message, Integer statusCode){
            this.errorCode = errorCode;
            this.message = message;
            this.statusCode = statusCode;
        }

        public ErrorMessage appendMessage(String message){
            this.message = this.message + message;
            return this;
        }
    }

}