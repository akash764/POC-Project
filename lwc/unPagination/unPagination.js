import { LightningElement, api } from 'lwc';

export default class UnPagination extends LightningElement {
    @api currentPage = 1;
    @api totalPages = 1;

    get isFirstPage() {
        return this.currentPage <= 1;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    handlePrevious() {
        if (!this.isFirstPage) {
            this.dispatchEvent(new CustomEvent('pagechange', {
                detail: { page: this.currentPage - 1 },
                bubbles: true,
                composed: true
            }));
        }
    }

    handleNext() {
        if (!this.isLastPage) {
            this.dispatchEvent(new CustomEvent('pagechange', {
                detail: { page: this.currentPage + 1 },
                bubbles: true,
                composed: true
            }));
        }
    }
}