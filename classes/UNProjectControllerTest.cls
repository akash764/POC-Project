@IsTest
private class UNProjectControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create 2 Projects (1 Apartment, 1 Villa)
        Project__c proj1 = new Project__c(
            Name = 'Urban Serenity',
            Project_Type__c = 'Residential_Apartment',
            City__c = 'Chennai',
            State__c = 'Tamil Nadu',
            Status__c = 'Under Construction',
            Start_Date__c = Date.today().addMonths(-6),
            End_Date__c = Date.today().addMonths(18),
            Public_Description__c = 'Luxury residential high-rise community.',
            Strengths__c = 'Clubhouse, Olympic Pool, Metro Access',
            Brochure_Content_Key__c = 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00'
        );
        Project__c proj2 = new Project__c(
            Name = 'Urban Palms',
            Project_Type__c = 'Residential_Villa',
            City__c = 'Bengaluru',
            State__c = 'Karnataka',
            Status__c = 'New Launch',
            Start_Date__c = Date.today().addMonths(-2),
            End_Date__c = Date.today().addMonths(24),
            Public_Description__c = 'Exclusive gated villa estate.',
            Strengths__c = 'Private Gardens, Solar Lighting',
            Brochure_Content_Key__c = 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c'
        );
        insert new List<Project__c>{ proj1, proj2 };

        // Create Phases
        Phase__c phaseA = new Phase__c(
            Name = 'Tower Azure',
            Project__c = proj1.Id,
            Phase_Type__c = 'Tower / Block',
            Address__c = '100 OMR Expressway',
            Total_Floors__c = 14,
            Construction_Status__c = 'Under Construction',
            Photo_Content_Key__c = 'MCK_AZURE_PHOTO'
        );
        Phase__c phaseB = new Phase__c(
            Name = 'Palm Enclave',
            Project__c = proj2.Id,
            Phase_Type__c = 'Villa Enclave',
            Address__c = '45 Whitefield Main Rd',
            Total_Floors__c = 2,
            Construction_Status__c = 'Not Started',
            Photo_Content_Key__c = 'MCK_PALM_PHOTO'
        );
        insert new List<Phase__c>{ phaseA, phaseB };

        Id aptRtId = Schema.SObjectType.Property_Unit__c.getRecordTypeInfosByDeveloperName().get('Apartment_Flat')?.getRecordTypeId();
        Id villaRtId = Schema.SObjectType.Property_Unit__c.getRecordTypeInfosByDeveloperName().get('Villa_Unit')?.getRecordTypeId();

        // Create Units under Tower Azure and Palm Enclave
        List<Property_Unit__c> units = new List<Property_Unit__c>{
            new Property_Unit__c(
                Name = 'Unit 101',
                Phase__c = phaseA.Id,
                RecordTypeId = aptRtId,
                Unit_Type__c = '2 BHK Luxury Flat',
                Floor__c = 1,
                BHK__c = '2 BHK',
                Carpet_Area__c = 1250,
                Price__c = 8500000,
                Facing__c = 'East',
                Bathrooms__c = 2,
                Parking_Available__c = true,
                Possession_Date__c = Date.today().addMonths(12),
                Status__c = 'Available'
            ),
            new Property_Unit__c(
                Name = 'Unit 102',
                Phase__c = phaseA.Id,
                RecordTypeId = aptRtId,
                Unit_Type__c = '3 BHK Premium Flat',
                Floor__c = 1,
                BHK__c = '3 BHK',
                Carpet_Area__c = 1750,
                Price__c = 12500000,
                Facing__c = 'North',
                Bathrooms__c = 3,
                Parking_Available__c = true,
                Possession_Date__c = Date.today().addMonths(12),
                Status__c = 'Under Offer'
            ),
            new Property_Unit__c(
                Name = 'Unit 103',
                Phase__c = phaseA.Id,
                RecordTypeId = aptRtId,
                Unit_Type__c = '3 BHK Premium Flat',
                Floor__c = 2,
                BHK__c = '3 BHK',
                Carpet_Area__c = 1750,
                Price__c = 13500000,
                Facing__c = 'North',
                Bathrooms__c = 3,
                Parking_Available__c = true,
                Possession_Date__c = Date.today().addMonths(12),
                Status__c = 'Sold'
            ),
            new Property_Unit__c(
                Name = 'Villa 01',
                Phase__c = phaseB.Id,
                RecordTypeId = villaRtId,
                Unit_Type__c = '3 BHK Luxury Villa',
                Plot_Area__c = 2400,
                Carpet_Area__c = 2800,
                BHK__c = '3 BHK',
                Price__c = 24000000,
                Facing__c = 'East',
                Bathrooms__c = 4,
                Parking_Available__c = true,
                Possession_Date__c = Date.today().addMonths(20),
                Status__c = 'Occupied'
            )
        };
        insert units;

        // Create Project Amenities
        insert new List<Project_Amenity__c>{
            new Project_Amenity__c(
                Name = 'Olympic Horizon Pool',
                Project__c = proj1.Id,
                Amenity_Type__c = 'Swimming Pool',
                Description__c = '50m temperature-controlled lap pool.',
                Photo_Content_Key__c = 'https://images.unsplash.com/photo-1577495508048-b635879837f1',
                Display_Order__c = 1,
                Is_Featured__c = true
            ),
            new Project_Amenity__c(
                Name = 'Club Azure',
                Project__c = proj1.Id,
                Amenity_Type__c = 'Clubhouse',
                Description__c = '25,000 sq.ft recreation center.',
                Photo_Content_Key__c = 'MCK_CLUB_AZURE',
                Display_Order__c = 2,
                Is_Featured__c = true
            )
        };
    }

    @IsTest
    static void testGetFeaturedProjects() {
        Test.startTest();
        List<UNProjectDTO> featured = UNProjectController.getFeaturedProjects(5);
        Test.stopTest();

        Assert.isNotNull(featured, 'Featured projects list should not be null');
        Assert.areEqual(2, featured.size(), 'Should return both configured projects');
        Assert.isNotNull(featured[0].startingPrice, 'Starting price should be calculated');
    }

    @IsTest
    static void testGetProjectsWithFilter() {
        Test.startTest();
        List<UNProjectDTO> chennaiProjects = UNProjectController.getProjects('Chennai', null, 10, 0);
        Integer totalCount = UNProjectController.getProjectsCount('Chennai', null);
        Test.stopTest();

        Assert.areEqual(1, chennaiProjects.size(), 'Should find 1 project in Chennai');
        Assert.areEqual('Urban Serenity', chennaiProjects[0].name);
        Assert.areEqual(1, totalCount);

        List<UNProjectDTO> villaProjects = UNProjectController.getProjectsByType(null, null, 'Residential_Villa', 10, 0);
        Integer villaCount = UNProjectController.getProjectsCountByType(null, null, 'Residential_Villa');
        Assert.areEqual(1, villaProjects.size(), 'Should find 1 villa project');
        Assert.areEqual('Urban Palms', villaProjects[0].name);
        Assert.areEqual(1, villaCount);
    }

    @IsTest
    static void testZeroAvailableUnitsProjectRemainsVisible() {
        Test.startTest();
        List<UNProjectDTO> allProjects = UNProjectController.getProjects(null, 'Karnataka', 10, 0);
        Test.stopTest();

        Assert.areEqual(1, allProjects.size(), 'Project with 0 available units MUST remain visible');
        Assert.areEqual('Urban Palms', allProjects[0].name);
        Assert.areEqual(0, allProjects[0].availableUnits, 'Available units should be 0');
    }

    @IsTest
    static void testGetProjectDetails() {
        Project__c proj = [SELECT Id FROM Project__c WHERE Name = 'Urban Serenity' LIMIT 1];

        Test.startTest();
        UNProjectDTO details = UNProjectController.getProjectDetails(proj.Id);
        Test.stopTest();

        Assert.isNotNull(details, 'Project details should be populated');
        Assert.areEqual('Urban Serenity', details.name);
        Assert.areEqual(1, details.phases.size(), 'Should have 1 phase');
        Assert.areEqual(2, details.phases[0].units.size(), 'Should have exactly 2 property units (Available & Under Offer; Sold excluded)');
        Assert.areEqual('Available', details.phases[0].units[0].status);
        Assert.areEqual('Under Offer', details.phases[0].units[1].status);
        Assert.areEqual(2, details.amenities.size(), 'Should have exactly 2 project amenities');
    }

    @IsTest
    static void testGetLocationFilterOptions() {
        Test.startTest();
        UNProjectService.LocationFilterOptions options = UNProjectController.getLocationFilterOptions();
        Test.stopTest();

        Assert.isNotNull(options, 'Location options should not be null');
        Assert.isTrue(options.cities.contains('Chennai'), 'Should contain Chennai');
        Assert.isTrue(options.states.contains('Tamil Nadu'), 'Should contain Tamil Nadu');
        Assert.isNotNull(options.stateCityMap, 'State city map should not be null');
        Assert.isTrue(options.stateCityMap.containsKey('Tamil Nadu'), 'Map should contain Tamil Nadu');
        Assert.isTrue(options.stateCityMap.get('Tamil Nadu').contains('Chennai'), 'Tamil Nadu should map to Chennai');
    }

    @IsTest
    static void testGetCompanyContactInfo() {
        Test.startTest();
        Map<String, String> info = UNProjectController.getCompanyContactInfo();
        Test.stopTest();

        Assert.isNotNull(info, 'Company contact info should not be null');
        Assert.isTrue(info.containsKey('address'), 'Should contain address');
        Assert.isTrue(info.containsKey('phone'), 'Should contain phone');
        Assert.isTrue(info.containsKey('email'), 'Should contain email');
        Assert.isTrue(info.containsKey('visitorHours'), 'Should contain visitor hours');
    }
}