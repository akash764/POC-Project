/**
 * @description Invocable Apex action to execute customized Lead Conversion from a Screen Flow.
 * Handles Lead conversion (New or Existing Account/Contact/Opportunity), 
 * Opportunity Project & Unit allocation, and Contact Role assignment.
 */
public with sharing class UNLeadConvertInvocable {

    public class ConvertRequest {
        @InvocableVariable(label='Lead ID' required=true)
        public String leadId;

        @InvocableVariable(label='Record Owner ID' required=false)
        public String ownerId;

        @InvocableVariable(label='Converted Status' required=false)
        public String convertedStatus;

        // Account
        @InvocableVariable(label='Existing Account ID' required=false)
        public String existingAccountId;

        @InvocableVariable(label='Account Record Type DeveloperName' required=false)
        public String accountRecordType;

        @InvocableVariable(label='Account Name' required=false)
        public String accountName;

        // Contact
        @InvocableVariable(label='Existing Contact ID' required=false)
        public String existingContactId;

        @InvocableVariable(label='Contact Role' required=false)
        public String contactRole;

        // Opportunity
        @InvocableVariable(label='Do Not Create Opportunity' required=false)
        public Boolean doNotCreateOpportunity;

        @InvocableVariable(label='Existing Opportunity ID' required=false)
        public String existingOpportunityId;

        @InvocableVariable(label='Opportunity Name' required=false)
        public String opportunityName;

        @InvocableVariable(label='Target Project ID' required=false)
        public String projectId;

        @InvocableVariable(label='Allocated Property Unit ID' required=false)
        public String propertyUnitId;

        @InvocableVariable(label='Close Date' required=false)
        public Date closeDate;
    }

    public class ConvertResult {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Account ID')
        public Id accountId;

        @InvocableVariable(label='Contact ID')
        public Id contactId;

        @InvocableVariable(label='Opportunity ID')
        public Id opportunityId;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(label='Convert Lead With Real Estate Allocation' description='Converts a Lead, supports Existing/New Account, Contact, Opportunity, and maps Project & Property Unit.')
    public static List<ConvertResult> convertLeads(List<ConvertRequest> requests) {
        List<ConvertResult> results = new List<ConvertResult>();

        // Query default converted status
        LeadStatus convertStatus = [
            SELECT Id, MasterLabel, ApiName 
            FROM LeadStatus 
            WHERE IsConverted = true 
            LIMIT 1
        ];

        for (ConvertRequest req : requests) {
            ConvertResult res = new ConvertResult();
            try {
                Id leadRecordId = String.isNotBlank(req.leadId) ? (Id)req.leadId.trim() : null;
                Id ownerRecordId = String.isNotBlank(req.ownerId) ? (Id)req.ownerId.trim() : null;
                Id existingAccId = String.isNotBlank(req.existingAccountId) ? (Id)req.existingAccountId.trim() : null;
                Id existingConId = String.isNotBlank(req.existingContactId) ? (Id)req.existingContactId.trim() : null;
                Id existingOppId = String.isNotBlank(req.existingOpportunityId) ? (Id)req.existingOpportunityId.trim() : null;
                Id projectRecordId = String.isNotBlank(req.projectId) ? (Id)req.projectId.trim() : null;
                Id unitRecordId = String.isNotBlank(req.propertyUnitId) ? (Id)req.propertyUnitId.trim() : null;

                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(leadRecordId);

                String targetStatus = String.isNotBlank(req.convertedStatus) ? req.convertedStatus : (convertStatus.ApiName != null ? convertStatus.ApiName : convertStatus.MasterLabel);
                lc.setConvertedStatus(targetStatus);

                if (ownerRecordId != null) {
                    lc.setOwnerId(ownerRecordId);
                }

                // Account: Existing vs New
                if (existingAccId != null) {
                    lc.setAccountId(existingAccId);
                }

                // Contact: Existing vs New
                if (existingConId != null) {
                    lc.setContactId(existingConId);
                }

                // Opportunity handling
                if (req.doNotCreateOpportunity == true) {
                    lc.setDoNotCreateOpportunity(true);
                } else if (existingOppId != null) {
                    lc.setOpportunityId(existingOppId);
                } else if (String.isNotBlank(req.opportunityName)) {
                    lc.setOpportunityName(req.opportunityName);
                }

                Database.LeadConvertResult lcr = Database.convertLead(lc);

                if (!lcr.isSuccess()) {
                    res.isSuccess = false;
                    List<String> errMsgs = new List<String>();
                    for (Database.Error err : lcr.getErrors()) {
                        errMsgs.add(err.getMessage());
                    }
                    res.errorMessage = String.join(errMsgs, '; ');
                    results.add(res);
                    continue;
                }

                res.isSuccess = true;
                res.accountId = lcr.getAccountId();
                res.contactId = lcr.getContactId();
                res.opportunityId = lcr.getOpportunityId();

                // Post-conversion updates on Account (only when new account was created)
                if (existingAccId == null && res.accountId != null) {
                    Account accToUpdate = new Account(Id = res.accountId);
                    Boolean updateAcc = false;

                    if (String.isNotBlank(req.accountName)) {
                        accToUpdate.Name = req.accountName;
                        updateAcc = true;
                    }

                    if (String.isNotBlank(req.accountRecordType)) {
                        Id accRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(req.accountRecordType)?.getRecordTypeId();
                        if (accRtId != null) {
                            accToUpdate.RecordTypeId = accRtId;
                            updateAcc = true;
                        }
                    }

                    if (updateAcc) {
                        update accToUpdate;
                    }
                }

                // Post-conversion updates on Contact
                if (res.contactId != null && String.isNotBlank(req.contactRole)) {
                    Contact conToUpdate = new Contact(
                        Id = res.contactId,
                        Role__c = req.contactRole
                    );
                    update conToUpdate;
                }

                // Post-conversion updates on Opportunity
                if (res.opportunityId != null) {
                    Opportunity oppToUpdate = new Opportunity(Id = res.opportunityId);
                    Boolean needsOppUpdate = false;

                    if (projectRecordId != null) {
                        oppToUpdate.Project__c = projectRecordId;
                        needsOppUpdate = true;
                    }

                    if (unitRecordId != null) {
                        oppToUpdate.Property_Unit__c = unitRecordId;
                        needsOppUpdate = true;
                    }

                    if (req.closeDate != null) {
                        oppToUpdate.CloseDate = req.closeDate;
                        needsOppUpdate = true;
                    }

                    // Update Opportunity FIRST while Unit is still Available
                    if (needsOppUpdate) {
                        update oppToUpdate;
                    }

                    // THEN reserve the property unit
                    if (unitRecordId != null) {
                        try {
                            Property_Unit__c unit = new Property_Unit__c(
                                Id = unitRecordId,
                                Status__c = 'Reserved'
                            );
                            update unit;
                        } catch (Exception ex) {
                            System.debug('Could not mark unit as Reserved: ' + ex.getMessage());
                        }
                    }

                    // Set Contact Role on Opportunity
                    if (res.contactId != null) {
                        String roleToSet = String.isNotBlank(req.contactRole) ? req.contactRole : 'Decision Maker';
                        List<OpportunityContactRole> existingRoles = [
                            SELECT Id, Role, IsPrimary 
                            FROM OpportunityContactRole 
                            WHERE OpportunityId = :res.opportunityId 
                              AND ContactId = :res.contactId
                            LIMIT 1
                        ];

                        if (!existingRoles.isEmpty()) {
                            existingRoles[0].Role = roleToSet;
                            existingRoles[0].IsPrimary = true;
                            update existingRoles[0];
                        } else {
                            OpportunityContactRole ocr = new OpportunityContactRole(
                                OpportunityId = res.opportunityId,
                                ContactId = res.contactId,
                                Role = roleToSet,
                                IsPrimary = true
                            );
                            insert ocr;
                        }
                    }
                }

            } catch (Exception ex) {
                res.isSuccess = false;
                res.errorMessage = ex.getMessage();
            }

            results.add(res);
        }

        return results;
    }
}