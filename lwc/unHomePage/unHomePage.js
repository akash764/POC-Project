import { LightningElement, track } from 'lwc';
import getFeaturedProjects from '@salesforce/apex/UNProjectController.getFeaturedProjects';

export default class UnHomePage extends LightningElement {
    @track featuredProjects = [];
    @track isLoadingProjects = true;
    @track hasProjectError = false;
    @track projectErrorMessage = '';

    connectedCallback() {
        this.loadFeaturedProjects();
    }

    async loadFeaturedProjects() {
        this.isLoadingProjects = true;
        this.hasProjectError = false;

        try {
            const data = await getFeaturedProjects({ limitCount: 6 });
            if (data && data.length > 0) {
                this.featuredProjects = data;
            } else {
                this.featuredProjects = this.getSampleProjects();
            }
        } catch (error) {
            console.warn('Using sample POC projects due to Apex query state:', error);
            this.featuredProjects = this.getSampleProjects();
        } finally {
            this.isLoadingProjects = false;
        }
    }

    get displayCountText() {
        const count = this.featuredProjects ? this.featuredProjects.length : 0;
        return `Showing ${count} of ${count} Developments`;
    }

    handleLocationSearch(event) {
        const { city, state } = event.detail;
        let targetUrl = './properties';
        const params = [];
        if (city) params.push(`city=${encodeURIComponent(city)}`);
        if (state) params.push(`state=${encodeURIComponent(state)}`);
        if (params.length > 0) {
            targetUrl += `?${params.join('&')}`;
        }
        window.location.href = targetUrl;
    }

    handleNavigateProperties() {
        window.location.href = './properties';
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

    handleOpenEnquiry() {
        window.dispatchEvent(new CustomEvent('openquickmodal', {
            detail: {
                projectName: 'General Project Consultation'
            }
        }));
    }

    getSampleProjects() {
        return [
            {
                id: 'sample-01',
                name: 'Urban Horizon Tech Park',
                projectType: 'Commercial',
                city: 'Hyderabad',
                state: 'Telangana',
                status: 'Active',
                startingPrice: 32000000,
                unitTypeOptions: ['Offices & Retail Suites'],
                totalPhases: 2,
                totalApartments: 2,
                availableUnits: 3,
                brochureContentKey: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=800&q=80',
                amenities: [
                    { id: 'a1', name: 'High-Speed EV Bays', amenityType: 'EV Charging Bays' },
                    { id: 'a2', name: 'Executive Business Lounge', amenityType: 'Co-Working Space' },
                    { id: 'a3', name: '24/7 Smart Security', amenityType: '24/7 Smart Security' }
                ]
            },
            {
                id: 'sample-02',
                name: 'Urban Palms Gated Villas',
                projectType: 'Residential_Villa',
                city: 'Bengaluru',
                state: 'Karnataka',
                status: 'Active',
                startingPrice: 26500000,
                bhkOptions: ['3 BHK', '4 BHK', '5 BHK'],
                totalPhases: 2,
                totalApartments: 2,
                availableUnits: 3,
                brochureContentKey: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
                amenities: [
                    { id: 'p1', name: 'Private Landscaped Gardens', amenityType: 'Landscaped Gardens' },
                    { id: 'p2', name: 'Championship Tennis Court', amenityType: 'Sports & Courts' },
                    { id: 'p3', name: 'Clubhouse & Spa', amenityType: 'Clubhouse' },
                    { id: 'p4', name: 'Children Play Area', amenityType: 'Kids Play Area' },
                    { id: 'p5', name: '24/7 Biometric Security', amenityType: '24/7 Smart Security' }
                ]
            },
            {
                id: 'sample-03',
                name: 'Urban Serenity',
                projectType: 'Residential_Apartment',
                city: 'Chennai',
                state: 'Tamil Nadu',
                status: 'Active',
                startingPrice: 7800000,
                bhkOptions: ['2 BHK', '3 BHK', '4 BHK'],
                totalPhases: 2,
                totalApartments: 2,
                availableUnits: 3,
                brochureContentKey: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
                amenities: [
                    { id: 's1', name: 'Olympic Horizon Pool', amenityType: 'Swimming Pool' },
                    { id: 's2', name: 'Club Azure Hub', amenityType: 'Clubhouse' },
                    { id: 's3', name: 'EV Charging Bays', amenityType: 'EV Charging Bays' }
                ]
            }
        ];
    }
}