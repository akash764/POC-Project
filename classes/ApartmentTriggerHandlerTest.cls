@isTest
private class ApartmentTriggerHandlerTest {

    private static final String DUP_MSG = 'A block with this name already exists in this project.';

    // ---------- Helpers ----------

    private static Project__c newProject(String name) {
        return new Project__c(
            Name = name,
            City__c = 'Chennai'
        );
    }

    private static Apartment__c newApt(Id projectId, String name) {
        return new Apartment__c(
            Name = name,
            Project__c = projectId,
            Total_Floors__c = 10
        );
    }

    // Puts the real error text first so a truncated column still shows it
    private static String errText(Database.SaveResult r) {
        return 'ERR=' + String.valueOf(r.getErrors());
    }

    // ---------- Insert tests ----------

    @isTest
    static void twoProjectsMayEachContainBlockA() {
        Project__c p1 = newProject('Project One');
        Project__c p2 = newProject('Project Two');
        insert new List<Project__c>{ p1, p2 };

        Test.startTest();
        List<Database.SaveResult> results = Database.insert(
            new List<Apartment__c>{ newApt(p1.Id, 'Block A'), newApt(p2.Id, 'Block A') },
            false
        );
        Test.stopTest();

        System.assert(results[0].isSuccess(), errText(results[0]));
        System.assert(results[1].isSuccess(), errText(results[1]));
    }

    @isTest
    static void sameProjectDuplicateIsBlocked_caseAndWhitespace() {
        Project__c p = newProject('Project One');
        insert p;
        insert newApt(p.Id, 'Block A');

        Test.startTest();
        Database.SaveResult exact  = Database.insert(newApt(p.Id, 'Block A'), false);
        Database.SaveResult spaced = Database.insert(newApt(p.Id, '  block a  '), false);
        Test.stopTest();

        System.assert(!exact.isSuccess(), 'Exact duplicate should fail');
        System.assert(!spaced.isSuccess(), 'Trimmed/case-insensitive duplicate should fail');
        System.assertEquals(DUP_MSG, exact.getErrors()[0].getMessage());
        System.assertEquals(DUP_MSG, spaced.getErrors()[0].getMessage());
    }

    @isTest
    static void bulkInsertDuplicatesInSameBatchAreBlocked() {
        Project__c p = newProject('Project One');
        insert p;

        Test.startTest();
        List<Database.SaveResult> results = Database.insert(
            new List<Apartment__c>{ newApt(p.Id, 'Block B'), newApt(p.Id, ' block b ') },
            false
        );
        Test.stopTest();

        System.assert(results[0].isSuccess(), errText(results[0]));
        System.assert(!results[1].isSuccess(), 'Second Block B in same batch should fail');
        System.assertEquals(1, [SELECT COUNT() FROM Apartment__c WHERE Project__c = :p.Id]);
    }

    @isTest
    static void blockWithoutProjectFails() {
        Test.startTest();
        Database.SaveResult r = Database.insert(newApt(null, 'Block A'), false);
        Test.stopTest();

        System.assert(!r.isSuccess(), 'Master-detail requires a Project');
    }

    @isTest
    static void bulkAcrossManyProjectsSucceeds() {
        List<Project__c> projects = new List<Project__c>();
        for (Integer i = 0; i < 50; i++) {
            projects.add(newProject('Project ' + i));
        }
        insert projects;

        List<Apartment__c> apts = new List<Apartment__c>();
        for (Project__c p : projects) {
            apts.add(newApt(p.Id, 'Block A'));
            apts.add(newApt(p.Id, 'Block B'));
        }

        Test.startTest();
        List<Database.SaveResult> results = Database.insert(apts, false);
        Test.stopTest();

        for (Database.SaveResult r : results) {
            System.assert(r.isSuccess(), errText(r));
        }
        System.assertEquals(100, [SELECT COUNT() FROM Apartment__c]);
    }

    // ---------- Update tests ----------
    // Each update sends only the Id plus the field being changed,
    // so Project__c (master-detail, no reparenting) is never part of the DML.

    @isTest
    static void renameToOwnNameWithDifferentCaseIsAllowed() {
        Project__c p = newProject('Project One');
        insert p;
        Apartment__c seed = newApt(p.Id, 'Block A');
        insert seed;

        Test.startTest();
        Apartment__c upd = new Apartment__c(Id = seed.Id, Name = ' block a ');
        Database.SaveResult r = Database.update(upd, false);
        Test.stopTest();

        System.assert(r.isSuccess(), errText(r));
    }

    @isTest
    static void renameToAnotherExistingNameIsBlocked() {
        Project__c p = newProject('Project One');
        insert p;
        Apartment__c seedA = newApt(p.Id, 'Block A');
        Apartment__c seedB = newApt(p.Id, 'Block B');
        insert new List<Apartment__c>{ seedA, seedB };

        Test.startTest();
        Apartment__c upd = new Apartment__c(Id = seedB.Id, Name = 'block a');
        Database.SaveResult r = Database.update(upd, false);
        Test.stopTest();

        System.assert(!r.isSuccess(), 'Rename to an existing name should fail');
        System.assert(r.getErrors()[0].getMessage() == DUP_MSG, errText(r));
    }

    @isTest
    static void unrelatedFieldUpdateIsAllowed() {
        Project__c p = newProject('Project One');
        insert p;
        Apartment__c seed = newApt(p.Id, 'Block A');
        insert seed;

        Test.startTest();
        Apartment__c upd = new Apartment__c(Id = seed.Id, Address__c = '12 Main Street');
        Database.SaveResult r = Database.update(upd, false);
        Test.stopTest();

        System.assert(r.isSuccess(), errText(r));
    }
}