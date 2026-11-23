/**
 * @description Lightning Web Component controller exposing real estate project APIs.
 * Enforces with sharing and relies on UNProjectService for allowlist query sanitization.
 */
public with sharing class UNProjectController {

    @AuraEnabled(cacheable=true)
    public static List<UNProjectDTO> getFeaturedProjects(Integer limitCount) {
        try {
            return UNProjectService.getFeaturedProjects(limitCount);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<UNProjectDTO> getProjects(String city, String state, Integer limitCount, Integer offsetCount) {
        try {
            return UNProjectService.getProjects(city, state, limitCount, offsetCount);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<UNProjectDTO> getProjectsByType(String city, String state, String projectType, Integer limitCount, Integer offsetCount) {
        try {
            return UNProjectService.getProjects(city, state, projectType, limitCount, offsetCount);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getProjectsCount(String city, String state) {
        try {
            return UNProjectService.getProjectsCount(city, state);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getProjectsCountByType(String city, String state, String projectType) {
        try {
            return UNProjectService.getProjectsCount(city, state, projectType);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static UNProjectDTO getProjectDetails(Id projectId) {
        try {
            return UNProjectService.getProjectDetails(projectId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static UNProjectService.LocationFilterOptions getLocationFilterOptions() {
        try {
            return UNProjectService.getLocationFilterOptions();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCompanyContactInfo() {
        try {
            return UNProjectService.getCompanyContactInfo();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}