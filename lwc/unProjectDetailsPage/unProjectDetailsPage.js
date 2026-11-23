import { LightningElement, api, track } from 'lwc';
import getProjectDetails from '@salesforce/apex/UNProjectController.getProjectDetails';
import getFeaturedProjects from '@salesforce/apex/UNProjectController.getFeaturedProjects';

const AMENITY_TYPE_FALLBACKS = {
    'swimming pool': 'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?auto=format&fit=crop&w=800&q=80',
    'clubhouse': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
    'fitness gym': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=800&q=80',
    'sports & courts': 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?auto=format&fit=crop&w=800&q=80',
    'kids play area': 'https://images.unsplash.com/photo-1566454544259-f4b94c3d758c?auto=format&fit=crop&w=800&q=80',
    'landscaped gardens': 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=800&q=80',
    'rooftop lounge': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
    'ev charging bays': 'https://images.unsplash.com/photo-1563986768609-322da13575f3?auto=format&fit=crop&w=800&q=80',
    '24/7 smart security': 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?auto=format&fit=crop&w=800&q=80',
    'co-working space': 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=800&q=80',
    'food court & cafeteria': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
    'corporate gym & wellness': 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?auto=format&fit=crop&w=800&q=80',
    'conference & seminar hall': 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&w=800&q=80',
    'convenience store & atm': 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=800&q=80',
    'daycare & creche': 'https://images.unsplash.com/photo-1587654780291-39c9404d746b?auto=format&fit=crop&w=800&q=80',
    'high-speed destination lifts': 'https://images.unsplash.com/photo-1541888946425-d0fbb18086f6?auto=format&fit=crop&w=800&q=80',
    '100% power backup': 'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?auto=format&fit=crop&w=800&q=80'
};

const AMENITY_TYPE_ICONS = {
    'swimming pool': '🏊',
    'clubhouse': '🏛️',
    'fitness gym': '🏋️',
    'sports & courts': '🎾',
    'kids play area': '🛝',
    'landscaped gardens': '🌳',
    'rooftop lounge': '🌇',
    'ev charging bays': '⚡',
    '24/7 smart security': '🛡️',
    'co-working space': '💼',
    'food court & cafeteria': '☕',
    'corporate gym & wellness': '🏋️',
    'conference & seminar hall': '🎤',
    'convenience store & atm': '🏪',
    'daycare & creche': '👶',
    'high-speed destination lifts': '🛗',
    '100% power backup': '⚡',
    'other': '✨'
};

export default class UnProjectDetailsPage extends LightningElement {
    @api recordId = '';
    @track project = {};
    @track selectedApartmentId = '';
    @track selectedUnitBhk = '';
    @track selectedUnitPrice = '';
    @track selectedUnitNumber = '';
    @track isLoading = true;

    get projectIdForReviews() {
        return this.recordId || this.project?.id || '';
    }

    connectedCallback() {
        this.extractRecordId();
        this.loadProject();
    }

    extractRecordId() {
        if (!this.recordId) {
            try {
                const params = new URLSearchParams(window.location.search);
                if (params.has('recordId')) {
                    this.recordId = params.get('recordId');
                } else if (params.has('id')) {
                    this.recordId = params.get('id');
                }
            } catch (e) {
                // Ignore query parameter errors
            }
        }
    }

    async loadProject() {
        this.isLoading = true;
        try {
            const hasValidSfId = this.recordId && 
                (this.recordId.length === 15 || this.recordId.length === 18) && 
                !this.recordId.startsWith('sample') && 
                !this.recordId.startsWith('proj');

            if (hasValidSfId) {
                const data = await getProjectDetails({ projectId: this.recordId });
                if (data && data.name) {
                    this.project = data;
                    if (data.apartments && data.apartments.length > 0) {
                        this.selectedApartmentId = data.apartments[0].id;
                    }
                    return;
                }
            }

            this.loadSampleData(this.recordId);
        } catch (err) {
            console.warn('Unable to load project from Apex, using sample presentation:', err);
            this.loadSampleData(this.recordId);
        } finally {
            this.isLoading = false;
        }
    }

    get statusBadgeClass() {
        const status = (this.project && this.project.status) ? this.project.status.toLowerCase() : 'plan';
        return `un-badge un-badge-${status}`;
    }

    get formattedStartingPrice() {
        if (this.project && this.project.startingPrice) {
            const p = this.project.startingPrice;
            if (p >= 10000000) return `₹ ${(p / 10000000).toFixed(2)} Cr*`;
            if (p >= 100000) return `₹ ${(p / 100000).toFixed(2)} Lacs*`;
            return `₹ ${p.toLocaleString('en-IN')}*`;
        }
        return 'Price On Request';
    }

    get isVilla() {
        return (this.project?.projectType || '').toLowerCase().includes('villa');
    }

    get isCommercial() {
        return (this.project?.projectType || '').toLowerCase().includes('commercial');
    }

    get phasesSectionTitle() {
        if (this.isVilla) return 'Villa Enclaves & Sectors';
        if (this.isCommercial) return 'Corporate Wings & Retail Promenades';
        return 'Towers & Wings';
    }

    get phasesCountPill() {
        const count = this.project?.totalPhases || (this.project?.phases?.length) || (this.project?.apartments?.length) || 0;
        if (this.isVilla) return `${count} Enclaves Configured`;
        if (this.isCommercial) return `${count} Wings Configured`;
        return `${count} Towers Configured`;
    }

    get phasesSectionHint() {
        if (this.isVilla) return 'Select an enclave below to browse its luxury villas, plot dimensions, and handover schedule.';
        if (this.isCommercial) return 'Select a wing below to inspect corporate offices, retail spaces, and leasable floor plans.';
        return 'Select a tower below to browse its residential units, floor specifications, and current availability.';
    }

    get unitsSectionTitle() {
        if (this.isVilla) return `Gated Villas: ${this.activeApartmentName}`;
        if (this.isCommercial) return `Commercial Suites: ${this.activeApartmentName}`;
        return `Residential Units: ${this.activeApartmentName}`;
    }

    get formattedBhkList() {
        if (this.isCommercial) {
            if (this.project && this.project.unitTypeOptions && this.project.unitTypeOptions.length > 0) {
                return this.project.unitTypeOptions.join(' | ');
            }
            return 'Offices & Retail Suites';
        }
        if (this.project && this.project.bhkOptions && this.project.bhkOptions.length > 0) {
            return this.project.bhkOptions.join(' | ');
        }
        return this.isVilla ? '3, 4 & 5 BHK Luxury Villas' : '1, 2 & 3 BHK';
    }

    get hasStrengths() {
        return Boolean(this.project && this.project.strengths);
    }

    get strengthItems() {
        if (!this.project || !this.project.strengths) return [];
        return this.project.strengths
            .split(/[,;\n]+/)
            .map(s => s.trim())
            .filter(s => s.length > 0);
    }

    get hasAmenities() {
        return Boolean(this.project && this.project.amenities && this.project.amenities.length > 0);
    }

    get amenitiesSectionTitle() {
        if (this.isCommercial) return 'Campus Facilities & Infrastructure';
        if (this.isVilla) return 'Enclave Amenities & Clubhouse Lifestyle';
        return 'Curated Amenities & Lifestyle';
    }

    get amenitiesSectionHint() {
        const name = this.project?.name || 'this development';
        if (this.isCommercial) {
            return `World-class corporate facilities, energy redundancy, and business infrastructure designed exclusively for ${name}.`;
        }
        if (this.isVilla) {
            return `Private club amenities, recreational retreats, and sports facilities designed exclusively for ${name} residents.`;
        }
        return `Handpicked modern amenities designed exclusively for ${name} residents.`;
    }

    get amenitiesCountPill() {
        const count = this.project?.amenities ? this.project.amenities.length : 0;
        return `${count} Exclusive Amenities`;
    }

    get amenityList() {
        if (!this.hasAmenities) return [];
        return this.project.amenities.map(a => {
            const typeKey = (a.amenityType || 'other').toLowerCase();
            let img = '';
            if (a.photoContentKey) {
                const key = a.photoContentKey.trim();
                if (key.startsWith('http://') || key.startsWith('https://') || key.startsWith('/')) {
                    img = key;
                } else {
                    img = `/cms/delivery/media/${key}`;
                }
            } else {
                img = AMENITY_TYPE_FALLBACKS[typeKey] || 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80';
            }

            return {
                id: a.id || a.name,
                name: a.name,
                amenityType: a.amenityType || 'Amenity',
                icon: AMENITY_TYPE_ICONS[typeKey] || '✨',
                description: a.description || '',
                imageUrl: img,
                isFeatured: Boolean(a.isFeatured)
            };
        });
    }

    get activeApartment() {
        if (!this.project || !this.project.apartments) return null;
        return this.project.apartments.find(a => a.id === this.selectedApartmentId) || this.project.apartments[0];
    }

    get activeApartmentName() {
        return this.activeApartment ? this.activeApartment.name : 'All Blocks';
    }

    get activeUnits() {
        return this.activeApartment && this.activeApartment.units ? this.activeApartment.units : [];
    }

    get enquiryTitle() {
        if (this.selectedUnitNumber) {
            return `Enquire for ${this.selectedUnitNumber} — ${this.project.name || 'this Project'}`;
        }
        return `Enquire about ${this.project.name || 'this Project'}`;
    }

    handleApartmentChange(event) {
        this.selectedApartmentId = event.detail.apartmentId;
    }

    handleUnitEnquire(event) {
        const detail = event.detail || {};
        const unitBhk = detail.bhk || detail.unitType || '';
        const unitBudget = detail.price ? String(detail.price) : '';
        const unitNum = detail.unitNumber || '';

        this.selectedUnitBhk = unitBhk;
        this.selectedUnitPrice = unitBudget;
        this.selectedUnitNumber = unitNum;

        window.dispatchEvent(new CustomEvent('openquickmodal', {
            detail: {
                projectId: this.project?.id || '',
                projectName: this.project?.name || '',
                unitNumber: unitNum,
                bhk: unitBhk,
                budget: unitBudget,
                price: unitBudget
            }
        }));
    }

    loadSampleData(identifier = '') {
        const idLower = String(identifier || '').toLowerCase();

        // 1. Urban Horizon Tech Park (Commercial, Hyderabad - Starting ₹ 3.20 Cr*)
        if (idLower === 'sample-01' || idLower === 'proj-03' || idLower.includes('horizon') || idLower.includes('tech')) {
            this.project = {
                id: 'sample-01',
                name: 'Urban Horizon Tech Park',
                projectType: 'Commercial',
                city: 'Hyderabad',
                state: 'Telangana',
                status: 'Active',
                startDate: '2025-01-15',
                endDate: '2027-12-31',
                publicDescription: 'Next-generation Grade-A corporate towers and vibrant high-street retail promenade engineered for Fortune 500 enterprises and luxury brands in HITEC City.',
                strengths: 'LEED Platinum Certified, Double-Glazed Acoustic Façade, High-Speed Destination Lifts, 100% DG Power Backup, Rooftop Helipad & Food Court',
                brochureContentKey: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
                totalApartments: 2,
                totalUnits: 6,
                availableUnits: 4,
                startingPrice: 32000000,
                unitTypeOptions: ['Offices & Retail Suites'],
                bhkOptions: ['Offices & Retail Suites'],
                amenities: [
                    {
                        id: 'am-h1',
                        name: 'High-Speed EV Bays',
                        amenityType: 'EV Charging Bays',
                        description: 'Dedicated high-speed electric vehicle charging stations across every bay.',
                        photoContentKey: 'https://images.unsplash.com/photo-1563986768609-322da13575f3?auto=format&fit=crop&w=800&q=80',
                        displayOrder: 1,
                        isFeatured: true
                    },
                    {
                        id: 'am-h2',
                        name: 'Executive Business Lounge',
                        amenityType: 'Co-Working Space',
                        description: 'Premium business lounges and private boardrooms with high-speed fiber connectivity.',
                        photoContentKey: 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=800&q=80',
                        displayOrder: 2,
                        isFeatured: true
                    },
                    {
                        id: 'am-h3',
                        name: '24/7 Smart Security',
                        amenityType: '24/7 Smart Security',
                        description: 'AI-assisted perimeter surveillance and biometric turnstile destination control.',
                        photoContentKey: 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?auto=format&fit=crop&w=800&q=80',
                        displayOrder: 3,
                        isFeatured: true
                    }
                ],
                apartments: [
                    {
                        id: 'ph-h1',
                        projectId: 'sample-01',
                        name: 'North Corporate Tower',
                        address: 'Plot 18, HITEC City Phase 2, Madhapur, Hyderabad',
                        totalFloors: 24,
                        constructionStatus: 'Completed',
                        numberOfUnits: 3,
                        availableUnits: 2,
                        units: [
                            {
                                id: 'u-h101',
                                unitNumber: 'NC-04-4A',
                                bhk: 'Offices & Retail Suites',
                                unitType: 'Corporate Office Suite',
                                floor: 4,
                                carpetArea: 2400,
                                superBuiltUpArea: 3100,
                                price: 32000000,
                                facing: 'East',
                                bathrooms: 2,
                                parkingAvailable: true,
                                possessionDate: '2026-12-31',
                                status: 'Available'
                            },
                            {
                                id: 'u-h102',
                                unitNumber: 'NC-09-9A',
                                bhk: 'Offices & Retail Suites',
                                unitType: 'Executive Office Floor',
                                floor: 9,
                                carpetArea: 3800,
                                superBuiltUpArea: 4900,
                                price: 44000000,
                                facing: 'North',
                                bathrooms: 4,
                                parkingAvailable: true,
                                possessionDate: '2026-12-31',
                                status: 'Available'
                            }
                        ]
                    },
                    {
                        id: 'ph-h2',
                        projectId: 'sample-01',
                        name: 'Retail Galleria Wing',
                        address: 'Galleria Plaza, HITEC City Phase 2, Madhapur, Hyderabad',
                        totalFloors: 4,
                        constructionStatus: 'Under Construction',
                        numberOfUnits: 3,
                        availableUnits: 2,
                        units: [
                            {
                                id: 'u-h201',
                                unitNumber: 'RG-00-GA',
                                bhk: 'Offices & Retail Suites',
                                unitType: 'High-Street Retail Showroom',
                                floor: 0,
                                carpetArea: 4200,
                                superBuiltUpArea: 5400,
                                price: 58000000,
                                facing: 'East',
                                bathrooms: 2,
                                parkingAvailable: true,
                                possessionDate: '2027-06-30',
                                status: 'Available'
                            }
                        ]
                    }
                ]
            };
            if (this.project.apartments && this.project.apartments.length > 0) {
                this.selectedApartmentId = this.project.apartments[0].id;
            }
            return;
        }

        // 2. Urban Palms Gated Villas (Villas, Bengaluru - Starting ₹ 2.65 Cr*)
        if (idLower === 'sample-02' || idLower === 'proj-02' || idLower.includes('palm') || idLower.includes('villa')) {
            this.project = {
                id: 'sample-02',
                name: 'Urban Palms Gated Villas',
                projectType: 'Residential_Villa',
                city: 'Bengaluru',
                state: 'Karnataka',
                status: 'Active',
                startDate: '2025-01-15',
                endDate: '2027-12-31',
                publicDescription: 'An ultra-exclusive gated villa estate set within 40 acres of private forest reserve, featuring Spanish-Mediterranean architecture with private plunge pools.',
                strengths: 'Private Temperature-Controlled Pools, 3-Car Covered Parking, 100% Vastu Compliant, 12-Acre Central Lake Park, Organic Kitchen Orchards',
                brochureContentKey: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
                totalApartments: 2,
                totalUnits: 6,
                availableUnits: 3,
                startingPrice: 26500000,
                bhkOptions: ['3 BHK', '4 BHK', '5 BHK'],
                amenities: [
                    {
                        id: 'am-p1',
                        name: 'Private Landscaped Gardens',
                        amenityType: 'Landscaped Gardens',
                        description: 'Private 1,200 sq.ft lawn with Mediterranean pergolas and drip irrigation.',
                        photoContentKey: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=800&q=80',
                        displayOrder: 1,
                        isFeatured: true
                    },
                    {
                        id: 'am-p2',
                        name: 'Championship Tennis Court',
                        amenityType: 'Sports & Courts',
                        description: 'Floodlit synthetic acrylic surface with resident coaching clinics.',
                        photoContentKey: 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?auto=format&fit=crop&w=800&q=80',
                        displayOrder: 2,
                        isFeatured: true
                    },
                    {
                        id: 'am-p3',
                        name: 'Clubhouse & Spa',
                        amenityType: 'Clubhouse',
                        description: '30,000 sq.ft private estate club with heated indoor pool and holistic wellness center.',
                        photoContentKey: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
                        displayOrder: 3,
                        isFeatured: true
                    }
                ],
                apartments: [
                    {
                        id: 'ph-p1',
                        projectId: 'sample-02',
                        name: 'Royal Palms Enclave',
                        address: 'Palm Boulevard, Whitefield-Sarjapur Link Rd, Bengaluru',
                        totalFloors: 2,
                        constructionStatus: 'Under Construction',
                        numberOfUnits: 3,
                        availableUnits: 2,
                        units: [
                            {
                                id: 'u-p101',
                                unitNumber: 'Palm Villa 07',
                                bhk: '3 BHK',
                                recordTypeName: 'Villa_Unit',
                                floor: 2,
                                plotArea: 2400,
                                carpetArea: 2750,
                                superBuiltUpArea: 3200,
                                price: 26500000,
                                facing: 'East',
                                bathrooms: 4,
                                parkingAvailable: true,
                                possessionDate: '2027-08-31',
                                status: 'Available'
                            },
                            {
                                id: 'u-p102',
                                unitNumber: 'Palm Villa 12',
                                bhk: '4 BHK',
                                recordTypeName: 'Villa_Unit',
                                floor: 2,
                                plotArea: 3600,
                                carpetArea: 4100,
                                superBuiltUpArea: 4750,
                                price: 42000000,
                                facing: 'North-East',
                                bathrooms: 5,
                                parkingAvailable: true,
                                possessionDate: '2027-10-31',
                                status: 'Available'
                            }
                        ]
                    }
                ]
            };
            if (this.project.apartments && this.project.apartments.length > 0) {
                this.selectedApartmentId = this.project.apartments[0].id;
            }
            return;
        }

        // 3. Urban Serenity (Apartments, Chennai - Starting ₹ 78.00 Lacs*)
        this.project = {
            id: 'sample-03',
            name: 'Urban Serenity',
            city: 'Chennai',
            state: 'Tamil Nadu',
            status: 'Active',
            startDate: '2025-01-15',
            endDate: '2027-12-31',
            publicDescription: 'Urban Serenity represents the pinnacle of contemporary high-rise residential architecture on the OMR IT Corridor. Spanning 7.5 lush acres with 78% open green expanses, it features high ceilings, oversized balconies, and IGBC Gold rated eco-amenities.',
            strengths: 'Olympic Infinity Pool, 25,000 sq.ft. Clubhouse, EV Fast Charging at Every Bay, IGBC Gold Certified, 300m from Upcoming Metro Station',
            brochureContentKey: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
            totalApartments: 2,
            totalUnits: 8,
            availableUnits: 3,
            startingPrice: 7800000,
            bhkOptions: ['2 BHK', '3 BHK', '4 BHK'],
            amenities: [
                {
                    id: 'am-01',
                    name: 'Olympic Horizon Pool',
                    amenityType: 'Swimming Pool',
                    description: 'Temperature-controlled 50m infinity lap pool with cabanas and panoramic deck views.',
                    photoContentKey: 'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?auto=format&fit=crop&w=800&q=80',
                    displayOrder: 1,
                    isFeatured: true
                },
                {
                    id: 'am-02',
                    name: 'Clubhouse & Wellness Spa',
                    amenityType: 'Clubhouse',
                    description: '25,000 sq.ft state-of-the-art recreation center, steam sauna, and executive banquet hall.',
                    photoContentKey: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
                    displayOrder: 2,
                    isFeatured: true
                },
                {
                    id: 'am-03',
                    name: 'Smart EV Charging Bays',
                    amenityType: 'EV Charging Bays',
                    description: 'Dedicated high-speed electric vehicle charging stations across every residential bay.',
                    photoContentKey: 'https://images.unsplash.com/photo-1563986768609-322da13575f3?auto=format&fit=crop&w=800&q=80',
                    displayOrder: 3,
                    isFeatured: false
                }
            ],
            apartments: [
                {
                    id: 'apt-01',
                    projectId: 'sample-03',
                    name: 'Tower Azure (Block A)',
                    address: 'Wing 1, 100 OMR Expressway, Navalur, Chennai',
                    totalFloors: 14,
                    constructionStatus: 'Under Construction',
                    numberOfUnits: 4,
                    availableUnits: 2,
                    units: [
                        {
                            id: 'u-101',
                            unitNumber: 'Azure 201',
                            bhk: '2 BHK',
                            floor: 2,
                            area: 1180,
                            carpetArea: 1180,
                            superBuiltUpArea: 1420,
                            price: 7800000,
                            facing: 'East',
                            bathrooms: 2,
                            parkingAvailable: true,
                            possessionDate: '2027-06-30',
                            status: 'Available'
                        },
                        {
                            id: 'u-102',
                            unitNumber: 'Azure 601',
                            bhk: '3 BHK',
                            floor: 6,
                            area: 1680,
                            carpetArea: 1680,
                            superBuiltUpArea: 2050,
                            price: 12500000,
                            facing: 'North-East',
                            bathrooms: 3,
                            parkingAvailable: true,
                            possessionDate: '2027-06-30',
                            status: 'Under Offer'
                        }
                    ]
                }
            ]
        };

        if (this.project.apartments && this.project.apartments.length > 0) {
            this.selectedApartmentId = this.project.apartments[0].id;
        }
    }
}