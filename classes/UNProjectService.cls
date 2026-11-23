/**
 * @description Service class handling real estate project and inventory queries.
 * Supports multi-asset classes: High-Rise Apartments, Luxury Villas, and Commercial Spaces.
 * Enforces strict public allowlists and ensures projects remain discoverable.
 */
public inherited sharing class UNProjectService {

    public class LocationFilterOptions {
        @AuraEnabled public List<String> cities { get; set; }
        @AuraEnabled public List<String> states { get; set; }
        @AuraEnabled public List<String> projectTypes { get; set; }
        @AuraEnabled public Map<String, List<String>> stateCityMap { get; set; }
    }

    /**
     * @description Retrieves featured projects for the homepage.
     */
    public static List<UNProjectDTO> getFeaturedProjects(Integer limitCount) {
        Integer queryLimit = (limitCount == null || limitCount <= 0 || limitCount > 20) ? 6 : limitCount;

        List<Project__c> projects = [
            SELECT Id, Name, Project_Type__c, City__c, State__c, Status__c, Start_Date__c, End_Date__c,
                   Public_Description__c, Strengths__c, Brochure_Content_Key__c, Total_Phases__c,
                   (SELECT Id, Name, Number_of_Units__c, Available_Units__c FROM Phases__r)
            FROM Project__c
            WHERE Status__c != null
            ORDER BY CreatedDate DESC
            LIMIT :queryLimit
        ];

        return mapProjectsToDTOs(projects);
    }

    /**
     * @description Retrieves projects with optional city/state/type filters and pagination.
     */
    public static List<UNProjectDTO> getProjects(String city, String state, Integer limitCount, Integer offsetCount) {
        return getProjects(city, state, null, limitCount, offsetCount);
    }

    public static List<UNProjectDTO> getProjects(String city, String state, String projectType, Integer limitCount, Integer offsetCount) {
        Integer safeLimit = (limitCount == null || limitCount <= 0 || limitCount > 50) ? 12 : limitCount;
        Integer safeOffset = (offsetCount == null || offsetCount < 0) ? 0 : offsetCount;

        String query = 'SELECT Id, Name, Project_Type__c, City__c, State__c, Status__c, Start_Date__c, End_Date__c, ' +
                       'Public_Description__c, Strengths__c, Brochure_Content_Key__c, Total_Phases__c, ' +
                       '(SELECT Id, Name, Number_of_Units__c, Available_Units__c FROM Phases__r) ' +
                       'FROM Project__c WHERE Status__c != null ';

        if (String.isNotBlank(city)) {
            query += ' AND City__c = :city ';
        }
        if (String.isNotBlank(state)) {
            query += ' AND State__c = :state ';
        }
        if (String.isNotBlank(projectType) && !'All'.equalsIgnoreCase(projectType)) {
            if (projectType.containsIgnoreCase('Villa')) {
                query += ' AND Project_Type__c IN (\'Residential_Villa\', \'Villa\', \'Villa Community\') ';
            } else if (projectType.containsIgnoreCase('Commercial')) {
                query += ' AND Project_Type__c IN (\'Commercial\', \'Commercial Space\') ';
            } else if (projectType.containsIgnoreCase('Apartment')) {
                query += ' AND Project_Type__c IN (\'Residential_Apartment\', \'Apartment\') ';
            } else {
                query += ' AND Project_Type__c = :projectType ';
            }
        }

        query += ' ORDER BY Name ASC LIMIT :safeLimit OFFSET :safeOffset ';

        List<Project__c> projects = Database.query(query);
        return mapProjectsToDTOs(projects);
    }

    /**
     * @description Returns total count of projects matching the criteria for pagination calculation.
     */
    public static Integer getProjectsCount(String city, String state) {
        return getProjectsCount(city, state, null);
    }

    public static Integer getProjectsCount(String city, String state, String projectType) {
        String query = 'SELECT COUNT() FROM Project__c WHERE Status__c != null ';
        if (String.isNotBlank(city)) {
            query += ' AND City__c = :city ';
        }
        if (String.isNotBlank(state)) {
            query += ' AND State__c = :state ';
        }
        if (String.isNotBlank(projectType) && !'All'.equalsIgnoreCase(projectType)) {
            if (projectType.containsIgnoreCase('Villa')) {
                query += ' AND Project_Type__c IN (\'Residential_Villa\', \'Villa\', \'Villa Community\') ';
            } else if (projectType.containsIgnoreCase('Commercial')) {
                query += ' AND Project_Type__c IN (\'Commercial\', \'Commercial Space\') ';
            } else if (projectType.containsIgnoreCase('Apartment')) {
                query += ' AND Project_Type__c IN (\'Residential_Apartment\', \'Apartment\') ';
            } else {
                query += ' AND Project_Type__c = :projectType ';
            }
        }
        return Database.countQuery(query);
    }

    /**
     * @description Retrieves complete project details including phases and property units.
     */
    public static UNProjectDTO getProjectDetails(Id projectId) {
        if (projectId == null) {
            throw new AuraHandledException('Invalid Project ID provided.');
        }

        List<Project__c> projects = [
            SELECT Id, Name, Project_Type__c, City__c, State__c, Status__c, Start_Date__c, End_Date__c,
                   Public_Description__c, Strengths__c, Brochure_Content_Key__c, Total_Phases__c,
                   (SELECT Id, Name, Phase_Type__c, Address__c, Total_Floors__c, Construction_Status__c,
                           Photo_Content_Key__c, Number_of_Units__c, Available_Units__c
                    FROM Phases__r
                    ORDER BY Name ASC),
                   (SELECT Id, Name, Amenity_Type__c, Description__c, Photo_Content_Key__c,
                           Display_Order__c, Is_Featured__c
                    FROM Project_Amenities__r
                    ORDER BY Display_Order__c ASC NULLS LAST, CreatedDate ASC)
            FROM Project__c
            WHERE Id = :projectId
            LIMIT 1
        ];

        if (projects.isEmpty()) {
            throw new AuraHandledException('Project not found.');
        }

        Project__c p = projects[0];
        UNProjectDTO projectDTO = new UNProjectDTO();
        projectDTO.id = p.Id;
        projectDTO.name = p.Name;
        projectDTO.projectType = (p.Project_Type__c != null) ? p.Project_Type__c : 'Apartment';
        projectDTO.city = p.City__c;
        projectDTO.state = p.State__c;
        projectDTO.status = p.Status__c;
        projectDTO.startDate = p.Start_Date__c;
        projectDTO.endDate = p.End_Date__c;
        projectDTO.publicDescription = p.Public_Description__c;
        projectDTO.strengths = p.Strengths__c;
        projectDTO.brochureContentKey = p.Brochure_Content_Key__c;
        projectDTO.totalPhases = (p.Total_Phases__c != null) ? Integer.valueOf(p.Total_Phases__c) : (p.Phases__r != null ? p.Phases__r.size() : 0);
        projectDTO.totalApartments = projectDTO.totalPhases;

        if (p.Project_Amenities__r != null && !p.Project_Amenities__r.isEmpty()) {
            for (Project_Amenity__c a : p.Project_Amenities__r) {
                UNAmenityDTO aDTO = new UNAmenityDTO();
                aDTO.id = a.Id;
                aDTO.name = a.Name;
                aDTO.amenityType = a.Amenity_Type__c;
                aDTO.description = a.Description__c;
                aDTO.photoContentKey = a.Photo_Content_Key__c;
                aDTO.displayOrder = (a.Display_Order__c != null) ? Integer.valueOf(a.Display_Order__c) : 1;
                aDTO.isFeatured = (a.Is_Featured__c == true);
                projectDTO.amenities.add(aDTO);
            }
        }

        Map<Id, UNPhaseDTO> phaseMap = new Map<Id, UNPhaseDTO>();
        for (Phase__c ph : p.Phases__r) {
            UNPhaseDTO phDTO = new UNPhaseDTO();
            phDTO.id = ph.Id;
            phDTO.projectId = p.Id;
            phDTO.name = ph.Name;
            phDTO.phaseType = ph.Phase_Type__c;
            phDTO.address = ph.Address__c;
            phDTO.totalFloors = (ph.Total_Floors__c != null) ? Integer.valueOf(ph.Total_Floors__c) : 0;
            phDTO.constructionStatus = ph.Construction_Status__c;
            phDTO.photoContentKey = ph.Photo_Content_Key__c;
            phDTO.numberOfUnits = (ph.Number_of_Units__c != null) ? Integer.valueOf(ph.Number_of_Units__c) : 0;
            phDTO.availableUnits = (ph.Available_Units__c != null) ? Integer.valueOf(ph.Available_Units__c) : 0;
            phaseMap.put(ph.Id, phDTO);
        }

        if (!phaseMap.isEmpty()) {
            Set<Id> phaseIds = phaseMap.keySet();
            // Filter: Only Available and Under Offer units appear on the public website.
            // Reserved, Sold, and Occupied units are strictly excluded from the portal view.
            List<Property_Unit__c> units = [
                SELECT Id, Name, Phase__c, RecordType.DeveloperName, Unit_Type__c, Floor__c, BHK__c,
                       Carpet_Area__c, Super_Built_Up_Area__c, Plot_Area__c, Price__c,
                       Facing__c, Bathrooms__c, Parking_Available__c, Furnishing_Status__c,
                       Possession_Date__c, Status__c, Sample_Photo_Content_Key__c
                FROM Property_Unit__c
                WHERE Phase__c IN :phaseIds
                  AND Status__c IN ('Available', 'Under Offer')
                ORDER BY Floor__c ASC, Name ASC
            ];

            Decimal minPrice = null;
            Set<String> bhkSet = new Set<String>();
            Set<String> unitTypeSet = new Set<String>();
            Integer totalAvail = 0;

            for (Property_Unit__c u : units) {
                UNPropertyUnitDTO uDTO = new UNPropertyUnitDTO();
                uDTO.id = u.Id;
                uDTO.phaseId = u.Phase__c;
                uDTO.unitNumber = u.Name;
                uDTO.recordTypeName = u.RecordType != null ? u.RecordType.DeveloperName : 'Apartment_Flat';
                uDTO.unitType = u.Unit_Type__c;
                uDTO.floor = (u.Floor__c != null) ? Integer.valueOf(u.Floor__c) : 0;
                uDTO.bhk = u.BHK__c;
                uDTO.carpetArea = u.Carpet_Area__c;
                uDTO.superBuiltUpArea = u.Super_Built_Up_Area__c;
                uDTO.plotArea = u.Plot_Area__c;
                uDTO.price = u.Price__c;
                uDTO.facing = u.Facing__c;
                uDTO.bathrooms = (u.Bathrooms__c != null) ? Integer.valueOf(u.Bathrooms__c) : 0;
                uDTO.parkingAvailable = u.Parking_Available__c;
                uDTO.furnishingStatus = u.Furnishing_Status__c;
                uDTO.possessionDate = u.Possession_Date__c;
                uDTO.status = u.Status__c;
                uDTO.samplePhotoContentKey = u.Sample_Photo_Content_Key__c;

                if (u.Price__c != null && (minPrice == null || u.Price__c < minPrice)) {
                    minPrice = u.Price__c;
                }
                if (String.isNotBlank(u.BHK__c)) {
                    bhkSet.add(u.BHK__c);
                }
                if (String.isNotBlank(u.Unit_Type__c)) {
                    unitTypeSet.add(u.Unit_Type__c);
                }
                if (u.Status__c == 'Available') {
                    totalAvail++;
                }

                if (phaseMap.containsKey(u.Phase__c)) {
                    phaseMap.get(u.Phase__c).units.add(uDTO);
                }
            }

            projectDTO.startingPrice = minPrice;
            projectDTO.bhkOptions = new List<String>(bhkSet);
            projectDTO.bhkOptions.sort();
            projectDTO.unitTypeOptions = new List<String>(unitTypeSet);
            projectDTO.unitTypeOptions.sort();
            projectDTO.totalUnits = units.size();
            projectDTO.availableUnits = totalAvail;
        }

        projectDTO.phases = phaseMap.values();
        return projectDTO;
    }

    /**
     * @description Provides distinct city and state options for UI search dropdowns.
     */
    public static LocationFilterOptions getLocationFilterOptions() {
        LocationFilterOptions options = new LocationFilterOptions();
        Set<String> citySet = new Set<String>();
        Set<String> stateSet = new Set<String>();
        Set<String> typeSet = new Set<String>();
        Map<String, Set<String>> stateCitySetMap = new Map<String, Set<String>>();

        for (Project__c p : [
            SELECT City__c, State__c, Project_Type__c
            FROM Project__c
            WHERE Status__c != null
        ]) {
            if (String.isNotBlank(p.City__c)) {
                citySet.add(p.City__c);
            }
            if (String.isNotBlank(p.State__c)) {
                stateSet.add(p.State__c);
                if (!stateCitySetMap.containsKey(p.State__c)) {
                    stateCitySetMap.put(p.State__c, new Set<String>());
                }
                if (String.isNotBlank(p.City__c)) {
                    stateCitySetMap.get(p.State__c).add(p.City__c);
                }
            }
            if (String.isNotBlank(p.Project_Type__c)) {
                typeSet.add(p.Project_Type__c);
            }
        }

        options.cities = new List<String>(citySet);
        options.cities.sort();
        options.states = new List<String>(stateSet);
        options.states.sort();
        options.projectTypes = new List<String>(typeSet);
        options.projectTypes.sort();

        Map<String, List<String>> stateCityMap = new Map<String, List<String>>();
        for (String st : stateCitySetMap.keySet()) {
            List<String> sortedCities = new List<String>(stateCitySetMap.get(st));
            sortedCities.sort();
            stateCityMap.put(st, sortedCities);
        }
        options.stateCityMap = stateCityMap;

        return options;
    }

    /**
     * @description Helper to transform Project__c list to public DTOs.
     */
    private static List<UNProjectDTO> mapProjectsToDTOs(List<Project__c> projects) {
        List<UNProjectDTO> dtos = new List<UNProjectDTO>();
        if (projects.isEmpty()) {
            return dtos;
        }

        Set<Id> projectIds = new Set<Id>();
        for (Project__c p : projects) {
            projectIds.add(p.Id);
        }

        Map<Id, Decimal> minPriceMap = new Map<Id, Decimal>();
        Map<Id, Set<String>> bhkMap = new Map<Id, Set<String>>();
        Map<Id, Set<String>> unitTypeMap = new Map<Id, Set<String>>();
        Map<Id, Integer> totalUnitsMap = new Map<Id, Integer>();
        Map<Id, Integer> availUnitsMap = new Map<Id, Integer>();

        for (Property_Unit__c u : [
            SELECT Id, BHK__c, Unit_Type__c, Price__c, Status__c, Phase__r.Project__c
            FROM Property_Unit__c
            WHERE Phase__r.Project__c IN :projectIds
              AND Status__c IN ('Available', 'Under Offer')
        ]) {
            Id pId = u.Phase__r.Project__c;

            Integer currentTotal = totalUnitsMap.containsKey(pId) ? totalUnitsMap.get(pId) : 0;
            totalUnitsMap.put(pId, currentTotal + 1);

            if (u.Status__c == 'Available') {
                Integer currentAvail = availUnitsMap.containsKey(pId) ? availUnitsMap.get(pId) : 0;
                availUnitsMap.put(pId, currentAvail + 1);
            }

            if (u.Price__c != null) {
                if (!minPriceMap.containsKey(pId) || u.Price__c < minPriceMap.get(pId)) {
                    minPriceMap.put(pId, u.Price__c);
                }
            }

            if (String.isNotBlank(u.BHK__c)) {
                if (!bhkMap.containsKey(pId)) {
                    bhkMap.put(pId, new Set<String>());
                }
                bhkMap.get(pId).add(u.BHK__c);
            }

            if (String.isNotBlank(u.Unit_Type__c)) {
                if (!unitTypeMap.containsKey(pId)) {
                    unitTypeMap.put(pId, new Set<String>());
                }
                unitTypeMap.get(pId).add(u.Unit_Type__c);
            }
        }

        Map<Id, List<UNAmenityDTO>> amenityMap = new Map<Id, List<UNAmenityDTO>>();
        for (Project_Amenity__c a : [
            SELECT Id, Name, Amenity_Type__c, Description__c, Photo_Content_Key__c,
                   Display_Order__c, Is_Featured__c, Project__c
            FROM Project_Amenity__c
            WHERE Project__c IN :projectIds
            ORDER BY Display_Order__c ASC NULLS LAST, CreatedDate ASC
        ]) {
            if (!amenityMap.containsKey(a.Project__c)) {
                amenityMap.put(a.Project__c, new List<UNAmenityDTO>());
            }
            UNAmenityDTO aDTO = new UNAmenityDTO();
            aDTO.id = a.Id;
            aDTO.name = a.Name;
            aDTO.amenityType = a.Amenity_Type__c;
            aDTO.description = a.Description__c;
            aDTO.photoContentKey = a.Photo_Content_Key__c;
            aDTO.displayOrder = (a.Display_Order__c != null) ? Integer.valueOf(a.Display_Order__c) : 1;
            aDTO.isFeatured = (a.Is_Featured__c == true);
            amenityMap.get(a.Project__c).add(aDTO);
        }

        for (Project__c p : projects) {
            UNProjectDTO dto = new UNProjectDTO();
            dto.id = p.Id;
            dto.name = p.Name;
            dto.projectType = (p.Project_Type__c != null) ? p.Project_Type__c : 'Residential_Apartment';
            dto.city = p.City__c;
            dto.state = p.State__c;
            dto.status = p.Status__c;
            dto.startDate = p.Start_Date__c;
            dto.endDate = p.End_Date__c;
            dto.publicDescription = p.Public_Description__c;
            dto.strengths = p.Strengths__c;
            dto.brochureContentKey = p.Brochure_Content_Key__c;
            dto.totalPhases = (p.Total_Phases__c != null) ? Integer.valueOf(p.Total_Phases__c) : (p.Phases__r != null ? p.Phases__r.size() : 0);
            dto.totalApartments = dto.totalPhases;

            if (amenityMap.containsKey(p.Id)) {
                dto.amenities = amenityMap.get(p.Id);
            }

            dto.startingPrice = minPriceMap.get(p.Id);
            if (bhkMap.containsKey(p.Id)) {
                dto.bhkOptions = new List<String>(bhkMap.get(p.Id));
                dto.bhkOptions.sort();
            }
            if (unitTypeMap.containsKey(p.Id)) {
                dto.unitTypeOptions = new List<String>(unitTypeMap.get(p.Id));
                dto.unitTypeOptions.sort();
            }
            dto.totalUnits = totalUnitsMap.containsKey(p.Id) ? totalUnitsMap.get(p.Id) : 0;
            dto.availableUnits = availUnitsMap.containsKey(p.Id) ? availUnitsMap.get(p.Id) : 0;

            dtos.add(dto);
        }

        return dtos;
    }

    /**
     * @description Retrieves company contact settings from Custom Metadata Type (UrbanNest_Contact_Setting__mdt)
     * with graceful fallback to default verified contact info.
     */
    public static Map<String, String> getCompanyContactInfo() {
        Map<String, String> info = new Map<String, String>{
            'address' => 'Level 12, Urban Horizon Center, IT Corridor, Chennai — 600096',
            'phone' => '+91 93636 47520',
            'phoneRaw' => '+919363647520',
            'email' => 'contact.urbannest360@gmail.com',
            'visitorHours' => 'Monday – Saturday: 9:30 AM – 6:30 PM (IST)'
        };

        try {
            UrbanNest_Contact_Setting__mdt setting = UrbanNest_Contact_Setting__mdt.getInstance('Default');
            if (setting != null) {
                if (String.isNotBlank(setting.Address__c)) {
                    info.put('address', setting.Address__c);
                }
                if (String.isNotBlank(setting.Phone_Number__c)) {
                    info.put('phone', setting.Phone_Number__c);
                    info.put('phoneRaw', setting.Phone_Number__c.replaceAll('[^0-9+]', ''));
                }
                if (String.isNotBlank(setting.Email__c)) {
                    info.put('email', setting.Email__c);
                }
                if (String.isNotBlank(setting.Visitor_Hours__c)) {
                    info.put('visitorHours', setting.Visitor_Hours__c);
                }
            }
        } catch (Exception ex) {
            // Graceful fallback to default values
        }
        return info;
    }
}