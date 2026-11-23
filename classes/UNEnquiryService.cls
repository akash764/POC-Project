/**
 * @description Service class handling public enquiry ingestion, validation,
 * idempotency, deduplication against phone/email, and follow-up task creation.
 * Follows BRD v1.4 US-2.07, US-3.01, and US-3.02.
 */
public without sharing class UNEnquiryService {

    private static final String DEFAULT_LEAD_SOURCE = 'Own Website';
    private static final String DEFAULT_LEAD_STATUS = 'New';
    private static final String NEUTRAL_SUCCESS_MSG = 'Thank you for your enquiry. An UrbanNest property advisor will contact you shortly.';
    private static final String DUPLICATE_PROJECT_ENQUIRY_MSG = 'Your enquiry for this project has already been submitted. Please wait, our sales executive will contact you soon.';

    /**
     * @description Ingests a public website enquiry.
     * Implements replay protection, phone/email deduplication per project, and returns a neutral response.
     */
    public static UNEnquiryResultDTO processEnquiry(UNEnquiryDTO input) {
        // 1. Server-side validation
        if (input == null) {
            return new UNEnquiryResultDTO(false, 'Enquiry data is missing.');
        }

        if (String.isBlank(input.fullName)) {
            return new UNEnquiryResultDTO(false, 'Please provide your name.');
        }

        if (String.isBlank(input.phone) && String.isBlank(input.email)) {
            return new UNEnquiryResultDTO(false, 'Please provide at least a phone number or email address.');
        }

        if (input.budget != null && input.budget < 0) {
            return new UNEnquiryResultDTO(false, 'Budget cannot be a negative value.');
        }

        String normalizedPhone = normalizePhone(input.phone);
        String normalizedEmail = normalizeEmail(input.email);

        // 2. Idempotency Check (Submission Key)
        if (String.isNotBlank(input.submissionKey)) {
            List<Lead> existingKeys = [
                SELECT Id 
                FROM Lead 
                WHERE Submission_Key__c = :input.submissionKey
                LIMIT 1
            ];
            if (!existingKeys.isEmpty()) {
                // Duplicate click or retry with identical submission key -> neutral success
                return new UNEnquiryResultDTO(true, NEUTRAL_SUCCESS_MSG);
            }
        }

        // Query Project Name for readable logging if ProjectId is provided
        String projectName = 'General UrbanNest Enquiry';
        String projectCity = '';
        if (input.projectId != null) {
            List<Project__c> matchedProjects = [SELECT Name, City__c FROM Project__c WHERE Id = :input.projectId LIMIT 1];
            if (!matchedProjects.isEmpty()) {
                projectName = matchedProjects[0].Name;
                projectCity = matchedProjects[0].City__c;
            }
        }

        // 3. Deduplication Check against existing Leads for the SAME Project
        List<Lead> duplicateLeads = findDuplicateLeadsForProject(normalizedPhone, normalizedEmail, input.projectId);

        if (!duplicateLeads.isEmpty()) {
            // Existing prospect already enquired for THIS exact project:
            // Do NOT create another Lead. Create a follow-up Task for the owner and inform the customer.
            Lead existingLead = duplicateLeads[0];
            createFollowUpTask(existingLead, input, projectName);
            if (input.campaignId != null) {
                attachCampaignMember(existingLead.Id, input.campaignId);
            }
            return new UNEnquiryResultDTO(false, DUPLICATE_PROJECT_ENQUIRY_MSG);
        }

        // 4. Create New Lead
        Lead newLead = new Lead();
        newLead.LastName = extractLastName(input.fullName);
        newLead.FirstName = extractFirstName(input.fullName);
        String location = String.isNotBlank(input.locationPreference) 
            ? input.locationPreference.trim().abbreviate(100) 
            : (String.isNotBlank(projectCity) ? projectCity : 'Chennai');
        newLead.Company = location;
        newLead.Location_Preference__c = location;
        newLead.LeadSource = DEFAULT_LEAD_SOURCE;
        newLead.Status = DEFAULT_LEAD_STATUS;
        newLead.Phone = input.phone;
        newLead.Email = input.email;
        newLead.Normalized_Phone__c = normalizedPhone;
        newLead.Normalized_Email__c = normalizedEmail;
        newLead.Budget__c = input.budget;
        newLead.BHK_Preference__c = String.isNotBlank(input.bhkPreference) ? input.bhkPreference.trim().abbreviate(100) : null;
        newLead.Preferred_Project__c = input.projectId;
        newLead.Submission_Key__c = input.submissionKey;
        newLead.WhatsApp_Opt_In__c = (input.whatsAppOptIn == true);

        try {
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.duplicateRuleHeader.allowSave = true;
            dml.assignmentRuleHeader.useDefaultRule = true;
            Database.insert(newLead, dml);

            if (input.campaignId != null) {
                attachCampaignMember(newLead.Id, input.campaignId);
            }
            return new UNEnquiryResultDTO(true, NEUTRAL_SUCCESS_MSG);
        } catch (DmlException dmlEx) {
            // Check if failure is due to a duplicate submission key race condition
            if (dmlEx.getMessage().contains('Submission_Key__c') || dmlEx.getMessage().contains('DUPLICATE_VALUE')) {
                return new UNEnquiryResultDTO(true, NEUTRAL_SUCCESS_MSG);
            }
            System.debug(LoggingLevel.ERROR, 'Lead insert failed: ' + dmlEx.getMessage());
            return new UNEnquiryResultDTO(false, 'Unable to submit enquiry at this time. Please try again.');
        }
    }

    /**
     * @description Searches for existing leads matching phone or email for the SAME project.
     * Guarantees that two blank inputs never match.
     * Allows a prospect to enquire for different projects.
     */
    private static List<Lead> findDuplicateLeadsForProject(String normPhone, String normEmail, Id projectId) {
        if (String.isBlank(normPhone) && String.isBlank(normEmail)) {
            return new List<Lead>();
        }

        if (projectId != null) {
            if (String.isNotBlank(normPhone) && String.isNotBlank(normEmail)) {
                return [
                    SELECT Id, OwnerId, Name, Email, Phone, Preferred_Project__c 
                    FROM Lead 
                    WHERE IsConverted = false
                      AND Preferred_Project__c = :projectId
                      AND ((Normalized_Phone__c = :normPhone AND Normalized_Phone__c != NULL) 
                        OR (Normalized_Email__c = :normEmail AND Normalized_Email__c != NULL)
                        OR (Phone = :normPhone AND Phone != NULL)
                        OR (Email = :normEmail AND Email != NULL))
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
            } else if (String.isNotBlank(normPhone)) {
                return [
                    SELECT Id, OwnerId, Name, Email, Phone, Preferred_Project__c 
                    FROM Lead 
                    WHERE IsConverted = false
                      AND Preferred_Project__c = :projectId
                      AND ((Normalized_Phone__c = :normPhone AND Normalized_Phone__c != NULL)
                        OR (Phone = :normPhone AND Phone != NULL))
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
            } else {
                return [
                    SELECT Id, OwnerId, Name, Email, Phone, Preferred_Project__c 
                    FROM Lead 
                    WHERE IsConverted = false
                      AND Preferred_Project__c = :projectId
                      AND ((Normalized_Email__c = :normEmail AND Normalized_Email__c != NULL)
                        OR (Email = :normEmail AND Email != NULL))
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
            }
        } else {
            // General enquiry without specific project
            if (String.isNotBlank(normPhone) && String.isNotBlank(normEmail)) {
                return [
                    SELECT Id, OwnerId, Name, Email, Phone, Preferred_Project__c 
                    FROM Lead 
                    WHERE IsConverted = false
                      AND Preferred_Project__c = NULL
                      AND ((Normalized_Phone__c = :normPhone AND Normalized_Phone__c != NULL) 
                        OR (Normalized_Email__c = :normEmail AND Normalized_Email__c != NULL)
                        OR (Phone = :normPhone AND Phone != NULL)
                        OR (Email = :normEmail AND Email != NULL))
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
            } else if (String.isNotBlank(normPhone)) {
                return [
                    SELECT Id, OwnerId, Name, Email, Phone, Preferred_Project__c 
                    FROM Lead 
                    WHERE IsConverted = false
                      AND Preferred_Project__c = NULL
                      AND ((Normalized_Phone__c = :normPhone AND Normalized_Phone__c != NULL)
                        OR (Phone = :normPhone AND Phone != NULL))
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
            } else {
                return [
                    SELECT Id, OwnerId, Name, Email, Phone, Preferred_Project__c 
                    FROM Lead 
                    WHERE IsConverted = false
                      AND Preferred_Project__c = NULL
                      AND ((Normalized_Email__c = :normEmail AND Normalized_Email__c != NULL)
                        OR (Email = :normEmail AND Email != NULL))
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
            }
        }
    }

    /**
     * @description Creates a follow-up Task on an existing Lead for duplicate enquiries.
     */
    private static void createFollowUpTask(Lead targetLead, UNEnquiryDTO input, String projectName) {
        try {
            Task followUp = new Task();
            followUp.WhoId = targetLead.Id;
            followUp.OwnerId = targetLead.OwnerId;
            followUp.Subject = 'New Website Enquiry: ' + projectName;
            followUp.Status = 'Not Started';
            followUp.Priority = 'High';
            followUp.ActivityDate = Date.today();

            String description = 'Prospect submitted a new enquiry from the UrbanNest website.\n\n' +
                'Enquired Project: ' + projectName + '\n' +
                'Location Preference: ' + (String.isNotBlank(input.locationPreference) ? input.locationPreference : 'Not Specified') + '\n' +
                'Preferred BHK: ' + (input.bhkPreference != null ? input.bhkPreference : 'Not Specified') + '\n' +
                'Budget: ' + (input.budget != null ? '₹ ' + input.budget.format() : 'Not Specified') + '\n' +
                'Phone: ' + (input.phone != null ? input.phone : 'N/A') + '\n' +
                'Email: ' + (input.email != null ? input.email : 'N/A') + '\n' +
                'WhatsApp Opt-In: ' + (input.whatsAppOptIn == true ? 'Yes' : 'No') + '\n' +
                'Submission Key: ' + (input.submissionKey != null ? input.submissionKey : 'N/A');

            followUp.Description = description;
            insert followUp;
        } catch (Exception ex) {
            // Task creation failure must not crash the guest user response
            System.debug(LoggingLevel.ERROR, 'Error creating follow-up task: ' + ex.getMessage());
        }
    }

    /**
     * @description Normalizes phone numbers to digits only.
     */
    public static String normalizePhone(String phone) {
        if (String.isBlank(phone)) {
            return null;
        }
        String digits = phone.replaceAll('[^0-9]', '');
        // If 12 digits starting with country code 91, keep last 10
        if (digits.length() == 12 && digits.startsWith('91')) {
            digits = digits.substring(2);
        }
        return String.isBlank(digits) ? null : digits;
    }

    /**
     * @description Normalizes email to lowercase trimmed string.
     */
    public static String normalizeEmail(String email) {
        if (String.isBlank(email)) {
            return null;
        }
        return email.trim().toLowerCase();
    }

    private static String extractFirstName(String fullName) {
        if (String.isBlank(fullName)) return '';
        List<String> parts = fullName.trim().split('\\s+');
        return parts.size() > 1 ? parts[0] : '';
    }

    private static String extractLastName(String fullName) {
        if (String.isBlank(fullName)) return 'Prospect';
        List<String> parts = fullName.trim().split('\\s+');
        if (parts.size() > 1) {
            parts.remove(0);
            return String.join(parts, ' ');
        }
        return parts[0];
    }

    /**
     * @description Attaches a lead as a member of a marketing campaign upon QR scan / web inquiry.
     */
    private static void attachCampaignMember(Id leadId, Id campaignId) {
        if (leadId == null || campaignId == null) {
            return;
        }
        try {
            List<CampaignMember> existing = [
                SELECT Id 
                FROM CampaignMember 
                WHERE CampaignId = :campaignId AND LeadId = :leadId 
                LIMIT 1
            ];
            if (existing.isEmpty()) {
                CampaignMember cm = new CampaignMember(
                    CampaignId = campaignId,
                    LeadId = leadId,
                    Status = 'Responded'
                );
                Database.insert(cm, false);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Could not attach CampaignMember: ' + ex.getMessage());
        }
    }
}