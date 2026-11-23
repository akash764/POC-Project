/**
 * @description Data Transfer Object for public Project details across Apartments, Villas, and Commercial spaces.
 */
public inherited sharing class UNProjectDTO {
    @AuraEnabled public Id id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String projectType { get; set; } // Apartment | Villa Community | Commercial
    @AuraEnabled public String city { get; set; }
    @AuraEnabled public String state { get; set; }
    @AuraEnabled public String status { get; set; }
    @AuraEnabled public Date startDate { get; set; }
    @AuraEnabled public Date endDate { get; set; }
    @AuraEnabled public String publicDescription { get; set; }
    @AuraEnabled public String strengths { get; set; }
    @AuraEnabled public String brochureContentKey { get; set; }
    @AuraEnabled public Integer totalPhases { get; set; }
    @AuraEnabled public Integer totalApartments { get; set; } // Alias for totalPhases
    @AuraEnabled public Integer totalUnits { get; set; }
    @AuraEnabled public Integer availableUnits { get; set; }
    @AuraEnabled public Decimal startingPrice { get; set; }
    @AuraEnabled public List<String> bhkOptions { get; set; }
    @AuraEnabled public List<String> unitTypeOptions { get; set; }
    @AuraEnabled public List<UNPhaseDTO> phases { get; set; }
    @AuraEnabled public List<UNAmenityDTO> amenities { get; set; }

    // Alias for phases to support any existing binding
    @AuraEnabled public List<UNPhaseDTO> apartments {
        get { return this.phases; }
        set { this.phases = value; }
    }

    public UNProjectDTO() {
        this.bhkOptions = new List<String>();
        this.unitTypeOptions = new List<String>();
        this.phases = new List<UNPhaseDTO>();
        this.amenities = new List<UNAmenityDTO>();
    }
}