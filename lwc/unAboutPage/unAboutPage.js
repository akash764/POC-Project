import { LightningElement, api } from 'lwc';

export default class UnAboutPage extends LightningElement {
    @api heroTitle = 'Pioneering Excellence in Urban Living';
    @api heroSubtitle = 'Discover our foundational values, uncompromising architectural philosophies, and fifteen-year legacy of creating benchmark residential communities.';
    @api companyHeading = 'Architectural Vision Meets Engineering Precision';

    handleNavigateProjects() {
        window.location.href = './properties';
    }

    handleNavigateContact() {
        window.location.href = './contact';
    }
}