@isTest
private class UNLeadConvertInvocableTest {

    @isTest
    static void testConvertLeadCreateNewAccount() {
        Project__c proj = new Project__c(
            Name = 'Grand Crest Residences',
            Status__c = 'Active',
            City__c = 'Bangalore'
        );
        insert proj;

        Phase__c phase = new Phase__c(
            Name = 'Tower A',
            Project__c = proj.Id,
            Phase_Type__c = 'Tower / Block'
        );
        insert phase;

        Id aptRtId = Schema.SObjectType.Property_Unit__c.getRecordTypeInfosByDeveloperName().get('Apartment_Flat')?.getRecordTypeId();

        Property_Unit__c unit = new Property_Unit__c(
            Name = 'GCR-101',
            Phase__c = phase.Id,
            RecordTypeId = aptRtId,
            Status__c = 'Available'
        );
        insert unit;

        Lead l = new Lead(
            FirstName = 'Kavi',
            LastName = 'Kumar',
            Company = 'Urban Corp',
            Email = 'kavikumar@example.com',
            Phone = '9876543210',
            Preferred_Project__c = proj.Id,
            Budget__c = 8000000
        );
        insert l;

        UNLeadConvertInvocable.ConvertRequest req = new UNLeadConvertInvocable.ConvertRequest();
        req.leadId = l.Id;
        req.accountRecordType = 'Individual_Buyer';
        req.accountName = 'Kavi Kumar (Individual Buyer)';
        req.projectId = proj.Id;
        req.propertyUnitId = unit.Id;
        req.contactRole = 'Primary Applicant';
        req.opportunityName = 'Kavi Kumar - Grand Crest';
        req.closeDate = Date.today().addDays(30);

        Test.startTest();
        List<UNLeadConvertInvocable.ConvertResult> results = UNLeadConvertInvocable.convertLeads(
            new List<UNLeadConvertInvocable.ConvertRequest>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess, 'Expected conversion to succeed: ' + results[0].errorMessage);
        System.assertNotEquals(null, results[0].accountId);
        System.assertNotEquals(null, results[0].contactId);
        System.assertNotEquals(null, results[0].opportunityId);

        Account acc = [SELECT Id, Name, RecordType.DeveloperName FROM Account WHERE Id = :results[0].accountId];
        System.assertEquals('Kavi Kumar (Individual Buyer)', acc.Name);

        Contact con = [SELECT Id, Role__c FROM Contact WHERE Id = :results[0].contactId];
        System.assertEquals('Primary Applicant', con.Role__c);

        Opportunity opp = [SELECT Id, Project__c, Property_Unit__c, CloseDate FROM Opportunity WHERE Id = :results[0].opportunityId];
        System.assertEquals(proj.Id, opp.Project__c);
        System.assertEquals(unit.Id, opp.Property_Unit__c);

        Property_Unit__c updatedUnit = [SELECT Id, Status__c FROM Property_Unit__c WHERE Id = :unit.Id];
        System.assertEquals('Reserved', updatedUnit.Status__c);
    }

    @isTest
    static void testConvertLeadExistingAccount() {
        Account existingAcc = new Account(Name = 'Existing Holdings Ltd');
        insert existingAcc;

        Lead l = new Lead(
            FirstName = 'Arun',
            LastName = 'Sharma',
            Company = 'Existing Holdings Ltd',
            Email = 'arunsharma@example.com'
        );
        insert l;

        UNLeadConvertInvocable.ConvertRequest req = new UNLeadConvertInvocable.ConvertRequest();
        req.leadId = l.Id;
        req.existingAccountId = existingAcc.Id;
        req.contactRole = 'Authorized Signatory';
        req.doNotCreateOpportunity = true;

        Test.startTest();
        List<UNLeadConvertInvocable.ConvertResult> results = UNLeadConvertInvocable.convertLeads(
            new List<UNLeadConvertInvocable.ConvertRequest>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess, 'Expected conversion to succeed: ' + results[0].errorMessage);
        System.assertEquals(existingAcc.Id, results[0].accountId);
    }
}