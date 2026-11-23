import { LightningElement, track, wire } from 'lwc';
import getProjectsByType from '@salesforce/apex/UNProjectController.getProjectsByType';
import getProjectsCountByType from '@salesforce/apex/UNProjectController.getProjectsCountByType';
import getLocationFilterOptions from '@salesforce/apex/UNProjectController.getLocationFilterOptions';

const PAGE_SIZE = 6;

export default class UnPropertiesPage extends LightningElement {
    @track selectedCity = '';
    @track selectedState = '';
    @track selectedType = 'All';
    @track currentPage = 1;
    @track totalProjectCount = 0;
    @track projects = [];
    @track isLoading = true;
    @track hasError = false;
    @track errorMessage = '';

    @track filterCities = [];
    @track filterStates = [];
    @track filterStateCityMap = {};

    connectedCallback() {
        this.parseUrlParameters();
        this.fetchProjects();
    }

    parseUrlParameters() {
        try {
            const urlParams = new URLSearchParams(window.location.search);
            if (urlParams.has('city')) {
                this.selectedCity = urlParams.get('city');
            }
            if (urlParams.has('state')) {
                this.selectedState = urlParams.get('state');
            }
            if (urlParams.has('type')) {
                const t = urlParams.get('type');
                if (t.toLowerCase().includes('villa')) {
                    this.selectedType = 'Residential_Villa';
                } else if (t.toLowerCase().includes('commercial')) {
                    this.selectedType = 'Commercial';
                } else if (t.toLowerCase().includes('apartment')) {
                    this.selectedType = 'Residential_Apartment';
                } else {
                    this.selectedType = t;
                }
            }
        } catch (e) {
            // URLSearchParams not available in test or SSR
        }
    }

    @wire(getLocationFilterOptions)
    wiredOptions({ data, error }) {
        if (data) {
            this.filterCities = data.cities || [];
            this.filterStates = data.states || [];
            this.filterStateCityMap = data.stateCityMap || {};
        } else if (error) {
            this.filterCities = ['Chennai', 'Bengaluru', 'Coimbatore', 'Hyderabad'];
            this.filterStates = ['Tamil Nadu', 'Karnataka', 'Telangana'];
            this.filterStateCityMap = {
                'Tamil Nadu': ['Chennai', 'Coimbatore'],
                'Karnataka': ['Bengaluru', 'Bangalore'],
                'Telangana': ['Hyderabad']
            };
        }
    }

    async fetchProjects() {
        this.isLoading = true;
        this.hasError = false;
        const offset = (this.currentPage - 1) * PAGE_SIZE;

        try {
            const [projectList, count] = await Promise.all([
                getProjectsByType({
                    city: this.selectedCity,
                    state: this.selectedState,
                    projectType: this.selectedType,
                    limitCount: PAGE_SIZE,
                    offsetCount: offset
                }),
                getProjectsCountByType({
                    city: this.selectedCity,
                    state: this.selectedState,
                    projectType: this.selectedType
                })
            ]);

            if (projectList && projectList.length > 0) {
                this.projects = projectList;
                this.totalProjectCount = count || projectList.length;
            } else if (!this.selectedCity && !this.selectedState) {
                let list = this.getFallbackPortfolio();
                if (this.selectedType && this.selectedType !== 'All') {
                    list = list.filter(p => p.projectType === this.selectedType);
                }
                this.projects = list;
                this.totalProjectCount = list.length;
            } else {
                this.projects = [];
                this.totalProjectCount = 0;
            }
        } catch (err) {
            console.warn('Error loading projects from Apex, displaying fallback:', err);
            let list = this.getFallbackPortfolio();
            if (this.selectedType && this.selectedType !== 'All') {
                list = list.filter(p => p.projectType === this.selectedType);
            }
            this.projects = list;
            this.totalProjectCount = list.length;
        } finally {
            this.isLoading = false;
        }
    }

    handleTypeTab(event) {
        const type = event.currentTarget.dataset.type;
        this.selectedType = type;
        this.currentPage = 1;
        this.fetchProjects();
    }

    get isAllActive() {
        return !this.selectedType || this.selectedType === 'All';
    }

    get isApartmentActive() {
        return this.selectedType === 'Residential_Apartment' || this.selectedType === 'Apartment';
    }

    get isVillaActive() {
        return this.selectedType === 'Residential_Villa' || this.selectedType === 'Villa';
    }

    get isCommercialActive() {
        return this.selectedType === 'Commercial';
    }

    get allTabClass() {
        return this.isAllActive ? 'un-type-tab active' : 'un-type-tab';
    }

    get apartmentTabClass() {
        return this.isApartmentActive ? 'un-type-tab active' : 'un-type-tab';
    }

    get villaTabClass() {
        return this.isVillaActive ? 'un-type-tab active' : 'un-type-tab';
    }

    get commercialTabClass() {
        return this.isCommercialActive ? 'un-type-tab active' : 'un-type-tab';
    }

    get totalPages() {
        return Math.ceil(this.totalProjectCount / PAGE_SIZE) || 1;
    }

    get showPagination() {
        return this.totalPages > 1;
    }

    get currentDisplayCount() {
        return this.projects ? this.projects.length : 0;
    }

    handleFilterChange(event) {
        this.selectedCity = event.detail.city;
        this.selectedState = event.detail.state;
        this.currentPage = 1;
        this.fetchProjects();
    }

    handleResetFilters() {
        this.selectedCity = '';
        this.selectedState = '';
        this.selectedType = 'All';
        this.currentPage = 1;
        this.fetchProjects();
    }

    handlePageChange(event) {
        this.currentPage = event.detail.page;
        this.fetchProjects();
        window.scrollTo({ top: 350, behavior: 'smooth' });
    }

    handleViewProjectDetails(event) {
        const projectId = event.detail.projectId;
        window.location.href = `./project-details?recordId=${projectId}`;
    }

    handleProjectEnquire(event) {
        window.dispatchEvent(new CustomEvent('openquickmodal', {
            detail: {
                projectId: event.detail.projectId,
                projectName: event.detail.projectName
            }
        }));
    }

    getFallbackPortfolio() {
        return [
            {
                id: 'proj-01',
                name: 'Urban Serenity',
                projectType: 'Residential_Apartment',
                city: 'Chennai',
                state: 'Tamil Nadu',
                status: 'Active',
                publicDescription: 'Luxury high-rise residential towers set across 7.5 pristine acres on the OMR IT Corridor with world-class clubhouse amenities.',
                totalPhases: 2,
                totalApartments: 2,
                totalUnits: 144,
                availableUnits: 38,
                startingPrice: 7800000,
                bhkOptions: ['2 BHK', '3 BHK', '4 BHK'],
                amenities: [
                    { id: 's1', name: 'Olympic Horizon Pool', amenityType: 'Swimming Pool' },
                    { id: 's2', name: 'Club Azure Hub', amenityType: 'Clubhouse' },
                    { id: 's3', name: 'EV Charging Bays', amenityType: 'EV Charging Bays' }
                ]
            },
            {
                id: 'proj-02',
                name: 'Urban Palms Gated Villas',
                projectType: 'Residential_Villa',
                city: 'Bengaluru',
                state: 'Karnataka',
                status: 'Active',
                publicDescription: 'Spanish-Mediterranean villas set within 40 acres of private forest reserve with private temperature-controlled pools.',
                totalPhases: 2,
                totalApartments: 2,
                totalUnits: 48,
                availableUnits: 12,
                startingPrice: 26500000,
                bhkOptions: ['3 BHK', '4 BHK', '5 BHK'],
                amenities: [
                    { id: 'p1', name: 'Private Landscaped Gardens', amenityType: 'Landscaped Gardens' },
                    { id: 'p2', name: 'Championship Tennis Court', amenityType: 'Sports & Courts' },
                    { id: 'p3', name: 'Clubhouse & Spa', amenityType: 'Clubhouse' },
                    { id: 'p4', name: 'Children Play Area', amenityType: 'Kids Play Area' },
                    { id: 'p5', name: '24/7 Biometric Security', amenityType: '24/7 Smart Security' }
                ]
            },
            {
                id: 'proj-03',
                name: 'Urban Horizon Tech Park',
                projectType: 'Commercial',
                city: 'Hyderabad',
                state: 'Telangana',
                status: 'Active',
                publicDescription: 'Grade-A corporate towers and vibrant high-street retail promenade engineered for Fortune 500 enterprises in HITEC City.',
                totalPhases: 2,
                totalApartments: 2,
                totalUnits: 36,
                availableUnits: 15,
                startingPrice: 32000000,
                unitTypeOptions: ['Corporate Office', 'Retail Showroom'],
                amenities: [
                    { id: 'a1', name: 'High-Speed EV Bays', amenityType: 'EV Charging Bays' },
                    { id: 'a2', name: 'Executive Business Lounge', amenityType: 'Co-Working Space' },
                    { id: 'a3', name: '24/7 Smart Security', amenityType: '24/7 Smart Security' }
                ]
            }
        ];
    }
}