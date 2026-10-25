export interface userAuthorType {
    id: number;
    user_id: number;
    bio: string | null;
    telegram_link: string | null;
    linkedin_link: string | null;
    facebook_link: string | null;
    whatsapp_link: string | null;
    status: string;
    auto_approve: number;
}

export interface userCategoryType {
    id: number;
    user_id: number;
    category_id: string;
    created_at: string;
    updated_at: string;
}

export interface userDetailsType {
    id: number;
    firebase_id: string;
    name: string;
    slug: string;
    type: string;
    email: string;
    mobile: string | null;
    profile: string | null;
    fcm_id: string | null;
    status: number;
    date: string;
    published_date: string;
    is_author: number;
    is_login: string;
    token?: string;
    user_category?: userCategoryType | null;
    author: userAuthorType | null;
}

export interface UserDataType {
    user: userDetailsType,
    token: string;
    is_new_user?: boolean;
}

export interface UserSliceType {
    token: string;
    user: userDetailsType,
    isLogin: boolean;
    isNewsUser: boolean;
    firebaseToken: string;
}
export interface ApiResponseType {
    error: boolean;
    message: string;
    data: any;
    code: number;
}

export interface ListApiResponseType<T> extends Omit<ApiResponseType, 'data'> {
    data: {
        total: number;
        data: T[];
    };
}

export interface PaginationLinkType {
    url: string | null;
    label: string;
    active: boolean;
}

export interface PaginatedApiResponseType<T> extends Omit<ApiResponseType, 'data'> {
    data: {
        current_page: number;
        data: T[];
        first_page_url: string;
        from: number | null;
        last_page: number;
        last_page_url: string;
        links: PaginationLinkType[];
        next_page_url: string | null;
        path: string;
        per_page: number;
        prev_page_url: string | null;
        to: number | null;
        total: number;
    };
}