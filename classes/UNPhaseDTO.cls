/**
 * @description Data Transfer Object for public Phase (Tower, Enclave, or Wing) details.
 */
public inherited sharing class UNPhaseDTO {
    @AuraEnabled public Id id { get; set; }
    @AuraEnabled public Id projectId { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String phaseType { get; set; }
    @AuraEnabled public String address { get; set; }
    @AuraEnabled public Integer totalFloors { get; set; }
    @AuraEnabled public String constructionStatus { get; set; }
    @AuraEnabled public String photoContentKey { get; set; }
    @AuraEnabled public Integer numberOfUnits { get; set; }
    @AuraEnabled public Integer availableUnits { get; set; }
    @AuraEnabled public List<UNPropertyUnitDTO> units { get; set; }

    public UNPhaseDTO() {
        this.units = new List<UNPropertyUnitDTO>();
    }
}