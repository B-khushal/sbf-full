// API Configuration - Production settings
export const API_URL = import.meta.env.VITE_API_URL || 'https://sbflorist.in/api';
export const UPLOADS_URL = import.meta.env.VITE_UPLOADS_URL || 'https://sbflorist.in';

// Utility function to construct proper image URLs with Cloudinary optimization
export const getImageUrl = (imagePath: string | undefined, options?: {
  width?: number;
  height?: number;
  crop?: string;
  quality?: string;
  format?: string;
  bustCache?: boolean;
}): string => {
  if (!imagePath) {
    return '/images/placeholder.jpg';
  }
  
  // If it's already a full Cloudinary URL, apply simplified transformations if needed
  if (imagePath.startsWith('https://res.cloudinary.com')) {
    // Check if transformations are already applied
    if (imagePath.includes('/c_scale') || imagePath.includes('/q_auto') || imagePath.includes('/f_auto')) {
      // Add cache busting for updated images if needed
      if (options?.bustCache) {
        return imagePath + `?_t=${Date.now()}`;
      }
      return imagePath;
    }
    
    // Apply simple transformations to existing Cloudinary URL
    const baseUrl = imagePath.split('/upload/')[0] + '/upload/';
    const imagePart = imagePath.split('/upload/')[1];
    
    const transformations = [];
    if (options?.width || options?.height) {
      const cropType = options?.crop || 'scale';
      let transform = `c_${cropType}`;
      if (options?.width) transform += `,w_${options.width}`;
      if (options?.height) transform += `,h_${options.height}`;
      transformations.push(transform);
    } else {
      transformations.push('c_scale,w_800'); // Default width scaling (reduced from 1000)
    }
    
    transformations.push('q_auto'); // Quality optimization
    transformations.push('f_auto'); // Format optimization
    
    let finalUrl = `${baseUrl}${transformations.join(',')}/${imagePart}`;
    
    // Add cache busting for updated images
    if (options?.bustCache) {
      finalUrl += `?_t=${Date.now()}`;
    }
    
    return finalUrl;
  }
  
  // If it's already a full URL (non-Cloudinary), return as is with optional cache busting
  if (imagePath.startsWith('http')) {
    if (options?.bustCache) {
      const url = new URL(imagePath);
      url.searchParams.set('_t', Date.now().toString());
      return url.toString();
    }
    return imagePath;
  }
  
  // For backward compatibility with local uploads
  // The upload route returns paths like "/uploads/image-123456.jpg"
  // We need to construct the full URL with the backend domain
  let finalUrl: string;
  if (imagePath.startsWith('/uploads/')) {
    finalUrl = `${UPLOADS_URL}${imagePath}`;
  } else if (imagePath.startsWith('/')) {
    finalUrl = `${UPLOADS_URL}${imagePath}`;
  } else {
    // If no leading slash, assume it's just the filename and add /uploads/
    finalUrl = `${UPLOADS_URL}/uploads/${imagePath}`;
  }
  
  // Add cache busting for updated images
  if (options?.bustCache) {
    const url = new URL(finalUrl);
    url.searchParams.set('_t', Date.now().toString());
    finalUrl = url.toString();
  }
  
  return finalUrl;
};

// Generate thumbnail URLs for product listings
export const getThumbnailUrl = (imagePath: string | undefined, size: number = 300, bustCache: boolean = false): string => {
  return getImageUrl(imagePath, {
    width: size,
    height: size,
    crop: 'fill',
    quality: 'auto',
    format: 'auto',
    bustCache
  });
};

// Generate optimized URLs for product detail pages
export const getProductImageUrl = (imagePath: string | undefined, width: number = 800, bustCache: boolean = false): string => {
  return getImageUrl(imagePath, {
    width: width,
    crop: 'scale',
    quality: 'auto',
    format: 'auto',
    bustCache
  });
};

// Generate square images with simplified transformations for consistent product grid display
export const getSquareImageUrl = (imagePath: string | undefined, size: number = 400, bustCache: boolean = false): string => {
  if (!imagePath) {
    return '/images/placeholder.svg';
  }
  
  // If it's already a full Cloudinary URL, apply simplified transformations
  if (imagePath.startsWith('https://res.cloudinary.com')) {
    const baseUrl = imagePath.split('/upload/')[0] + '/upload/';
    const imagePart = imagePath.split('/upload/')[1];
    
    // Apply simplified transformations for square aspect ratio
    const transformations = [
      `c_fill,w_${size},h_${size}`,  // Fill and crop to square
      'q_auto',                       // Auto quality
      'f_auto'                       // Auto format
    ];
    
    let finalUrl = `${baseUrl}${transformations.join(',')}/${imagePart}`;
    
    // Add cache busting for updated images
    if (bustCache) {
      finalUrl += `?_t=${Date.now()}`;
    }
    
    return finalUrl;
  }
  
  // For non-Cloudinary URLs, fall back to regular thumbnail
  return getThumbnailUrl(imagePath, size, bustCache);
};

// Generate enhanced product images with optional generative fill
export const getEnhancedProductImageUrl = (
  imagePath: string | undefined, 
  options?: {
    width?: number;
    height?: number;
    aspectRatio?: string;
    useGenFill?: boolean;
  }
): string => {
  const {
    width = 800,
    height = 600,
    aspectRatio = '4:3',
    useGenFill = true
  } = options || {};
  
  if (!imagePath) {
    return '/images/placeholder.jpg';
  }
  
  // If it's already a full Cloudinary URL, apply enhanced transformations
  if (imagePath.startsWith('https://res.cloudinary.com')) {
    const baseUrl = imagePath.split('/upload/')[0] + '/upload/';
    const imagePart = imagePath.split('/upload/')[1];
    
    const transformations = [];
    
    // Apply generative fill if requested
    if (useGenFill) {
      transformations.push(`ar_${aspectRatio.replace(':', '_')},g_center,b_gen_fill,c_pad`);
    }
    
    // Scale to target dimensions
    transformations.push(`w_${width},h_${height},c_scale`);
    
    // Optimize quality and format
    transformations.push('q_auto:best');
    transformations.push('f_auto');
    
    return `${baseUrl}${transformations.join('/')}/${imagePart}`;
  }
  
  // For non-Cloudinary URLs, fall back to regular optimization
  return getImageUrl(imagePath, { width, height: height, crop: 'scale' });
};

// Cache busting utility for when images are updated
export const addCacheBuster = (url: string): string => {
  const separator = url.includes('?') ? '&' : '?';
  return `${url}${separator}_t=${Date.now()}`;
};

// Get image URL with optional cache busting for updated products
export const getImageUrlWithCacheBuster = (imagePath: string | undefined, options?: {
  width?: number;
  height?: number;
  crop?: string;
  forceCacheBust?: boolean;
}): string => {
  const baseUrl = getImageUrl(imagePath, {
    width: options?.width,
    height: options?.height,
    crop: options?.crop,
    bustCache: false
  });
  
  return options?.forceCacheBust ? addCacheBuster(baseUrl) : baseUrl;
};

// Other configuration constants can be added here
export const ITEMS_PER_PAGE = 10;
export const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
export const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp']; 