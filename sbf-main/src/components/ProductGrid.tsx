import React, { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { cn } from "@/lib/utils";
import { useCurrency } from "@/contexts/CurrencyContext";
import { Heart, ShoppingBag, Star, ArrowRight, Sparkles, Wand2, ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import useCart from "@/hooks/use-cart";
import useWishlist from "@/hooks/use-wishlist";
import { useAuth } from "@/hooks/use-auth";
import { getImageUrl } from "@/config";
import { ComboItem } from "@/services/productService";

export type Product = {
  _id: string;
  title: string;
  price: number;
  discount: number;
  images: string[];
  category: string;
  categories?: string[];
  description?: string;
  createdAt?: string;
  featured?: boolean;
  isNewArrival?: boolean;
  isFeatured?: boolean;
  isCustomizable?: boolean;
  hidden?: boolean;
  customizationOptions?: {
    allowPhotoUpload: boolean;
    allowNumberInput: boolean;
    numberInputLabel: string;
    allowMessageCard: boolean;
    messageCardPrice: number;
    addons: {
      flowers: Array<{ name: string; price: number; type: 'flower' }>;
      chocolates: Array<{ name: string; price: number; type: 'chocolate' }>;
    };
    previewImage: string;
  };
  // Combo-specific fields
  comboItems?: ComboItem[];
  comboName?: string;
  comboDescription?: string;
};

type ProductGridProps = {
  products: Product[];
  title?: string;
  subtitle?: string;
  className?: string;
  loading?: boolean;
  onAddToCart?: (item: any, quantity: number) => boolean;
  horizontal?: boolean;
};

const ProductGrid = ({ products, title, subtitle, className, loading, onAddToCart, horizontal }: ProductGridProps) => {
  const scrollRef = useRef<HTMLDivElement>(null);

  // Auto-scroll logic
  useEffect(() => {
    if (!horizontal || !products.length) return;
    const container = scrollRef.current;
    if (!container) return;
    let scrollAmount = 1.2; // px per frame
    let reqId: number;
    let isHovered = false;
    // Expose a way to set isHovered from outside (arrow click)
    (container as any)._setIsHovered = (val: boolean) => { isHovered = val; };

    const step = () => {
      if (!container) return;
      if (!isHovered) {
        if (container.scrollLeft + container.offsetWidth >= container.scrollWidth - 2) {
          // Loop back to start
          container.scrollTo({ left: 0, behavior: 'auto' });
        } else {
          container.scrollLeft += scrollAmount;
        }
      }
      reqId = requestAnimationFrame(step);
    };
    reqId = requestAnimationFrame(step);

    // Pause on hover
    const onMouseEnter = () => { isHovered = true; };
    const onMouseLeave = () => { isHovered = false; };
    container.addEventListener('mouseenter', onMouseEnter);
    container.addEventListener('mouseleave', onMouseLeave);

    return () => {
      cancelAnimationFrame(reqId);
      container.removeEventListener('mouseenter', onMouseEnter);
      container.removeEventListener('mouseleave', onMouseLeave);
      delete (container as any)._setIsHovered;
    };
  }, [horizontal, products.length]);

  // Manual scroll
  const scrollBy = (direction: 'left' | 'right') => {
    if (scrollRef.current) {
      const container = scrollRef.current;
      const scrollAmount = Math.floor(container.offsetWidth * 0.8);
      container.scrollBy({ left: direction === 'left' ? -scrollAmount : scrollAmount, behavior: 'smooth' });
      // Pause auto-scroll when arrow is clicked
      if ((container as any)._setIsHovered) {
        (container as any)._setIsHovered(true);
      }
    }
  };

  return (
    <section className={cn("py-8 sm:py-12 lg:py-16 xl:py-20 px-3 sm:px-4 md:px-6 lg:px-8", className)}>
      {(title || subtitle) && (
        <div className="text-center mb-6 sm:mb-8 lg:mb-12 xl:mb-16">
          {title && (
            <h2 className="text-xl sm:text-2xl md:text-3xl lg:text-4xl xl:text-5xl font-bold tracking-tight mb-2 sm:mb-3 lg:mb-4 bg-gradient-to-r from-primary via-purple-600 to-pink-600 bg-clip-text text-transparent text-center">
              {title}
            </h2>
          )}
          {subtitle && (
            <p className="text-muted-foreground max-w-2xl mx-auto text-sm sm:text-base lg:text-lg xl:text-xl leading-relaxed px-2 text-center">
              {subtitle}
            </p>
          )}
        </div>
      )}

      {loading ? (
        <div className="text-center py-8 sm:py-12 lg:py-16">
          <div className="inline-block w-8 h-8 sm:w-12 sm:h-12 lg:w-16 lg:h-16 border-4 border-primary border-t-transparent rounded-full animate-spin mb-3 sm:mb-4"></div>
          <p className="text-gray-600 text-sm sm:text-base lg:text-lg text-center">Loading products...</p>
        </div>
      ) : products.length === 0 ? (
        <div className="text-center py-8 sm:py-12 lg:py-16">
          <div className="text-3xl sm:text-4xl lg:text-6xl mb-3 sm:mb-4 text-center">🌸</div>
          <p className="text-muted-foreground text-sm sm:text-base lg:text-lg text-center">No products available at the moment.</p>
        </div>
      ) : horizontal ? (
        <div className="relative">
          <button
            aria-label="Scroll left"
            className="absolute left-0 top-1/2 -translate-y-1/2 z-20 bg-white/80 hover:bg-primary/80 hover:text-white text-primary shadow rounded-full p-2 transition-all duration-200"
            style={{ display: products.length > 2 ? 'block' : 'none' }}
            onClick={() => scrollBy('left')}
          >
            <ChevronLeft className="w-6 h-6" />
          </button>
          <div
            ref={scrollRef}
            className="flex gap-4 overflow-x-auto pb-4 scrollbar-thin scrollbar-thumb-primary/40 scrollbar-track-transparent scroll-smooth"
            style={{ scrollBehavior: 'smooth' }}
          >
            {products.map((product) => (
              <div className="min-w-[220px] max-w-xs flex-shrink-0" key={product._id}>
                <ProductCard product={product} onAddToCart={onAddToCart} />
              </div>
            ))}
          </div>
          <button
            aria-label="Scroll right"
            className="absolute right-0 top-1/2 -translate-y-1/2 z-20 bg-white/80 hover:bg-primary/80 hover:text-white text-primary shadow rounded-full p-2 transition-all duration-200"
            style={{ display: products.length > 2 ? 'block' : 'none' }}
            onClick={() => scrollBy('right')}
          >
            <ChevronRight className="w-6 h-6" />
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 xs:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-3 gap-4 sm:gap-5 md:gap-6 lg:gap-7 xl:gap-9">
          {products.map((product) => (
            <ProductCard key={product._id} product={product} onAddToCart={onAddToCart} />
          ))}
        </div>
      )}
    </section>
  );
};

const getComboMaxPrice = (product: Product) => {
  if (product.category !== 'combos' || !product.comboItems) return product.price;
  let total = product.price;
  product.comboItems.forEach(item => {
    if (item.customizationOptions && item.customizationOptions.allowVariants && item.customizationOptions.variants && item.customizationOptions.variants.length > 0) {
      // Use the max variant price
      const maxVariant = item.customizationOptions.variants.reduce((max, v) => v.price > max ? v.price : max, 0);
      total += maxVariant;
    } else {
      total += item.price;
    }
  });
  return total;
};

const ProductCard = ({ product, onAddToCart }: { 
  product: Product; 
  onAddToCart?: (item: any, quantity: number) => boolean;
}) => {
  const { formatPrice, convertPrice } = useCurrency();
  const { addToCart } = useCart();
  const { addItem: addToWishlist, removeItem: removeFromWishlist, items: wishlistItems } = useWishlist();
  const navigate = useNavigate();
  const [isImageLoaded, setIsImageLoaded] = useState(false);
  const { user } = useAuth();

  const isInWishlist = wishlistItems.some(item => item.id === product._id);

  // Handle main card click - redirect to product details
  const handleCardClick = (e: React.MouseEvent) => {
    // Only navigate if the click isn't on a button
    if ((e.target as HTMLElement).closest('button')) {
      return;
    }
    console.log("Card clicked, navigating to product:", product._id);
    window.open(`/product/${product._id}`, '_blank', 'noopener,noreferrer');
  };

  // Handle add to cart
  const handleAddToCart = async (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    console.log("Add to cart clicked:", product.title);
    
    if (!user) {
      toast.error("Please login first to add items to your cart", {
        description: "You'll be redirected to the login page",
        duration: 3000,
      });
      setTimeout(() => {
        navigate('/login', { 
          state: { 
            redirect: window.location.pathname,
            message: "Please login to add items to your cart"
          } 
        });
      }, 1500);
      return;
    }
    
    try {
      const addToCartFunction = onAddToCart || addToCart;
      
      // Calculate discounted price if needed
      const discountedPrice = product.discount && product.discount > 0
        ? Math.round(product.price * (1 - product.discount / 100))
        : product.price;
      
      // Create cart item with proper structure
      const cartItem = {
        _id: product._id,
        title: product.title,
        price: discountedPrice,
        images: product.images || [],
        quantity: 1,
        discount: product.discount || 0,
        category: product.category,
        description: product.description,
      };
      
      console.log("Adding to cart:", cartItem);
      addToCartFunction(cartItem, 1);
      
      toast.success("🛒 Added to cart!", {
        description: `${product.title} has been added to your cart`,
        duration: 3000,
      });
    } catch (error) {
      console.error("Error adding to cart:", error);
      toast.error("Failed to add to cart", {
        description: "Please try again",
        duration: 3000,
      });
    }
  };

  // Handle wishlist toggle
  const handleWishlistToggle = async (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    console.log("Wishlist toggle clicked:", product._id);
    
    if (!user) {
      toast.error("Please login first to add items to your wishlist", {
        description: "You'll be redirected to the login page",
        duration: 3000,
      });
      // Redirect to login page with current page as redirect path
      setTimeout(() => {
        navigate('/login', { 
          state: { 
            redirect: window.location.pathname,
            message: "Please login to manage your wishlist"
          } 
        });
      }, 1500);
      return;
    }
    
    try {
      const wishlistItem = {
        id: String(product._id),
        title: product.title,
        image: product.images?.[0] || '/images/placeholder.svg',
        price: product.price
      };

      if (isInWishlist) {
        await removeFromWishlist(String(product._id));
      } else {
        await addToWishlist(wishlistItem);
      }
    } catch (error) {
      console.error("Error updating wishlist:", error);
      const errorMessage = error instanceof Error ? error.message : 'Failed to update wishlist';
      
      if (errorMessage.includes('log in')) {
        toast.error("Please login first to manage your wishlist", {
          description: "You'll be redirected to the login page",
          duration: 3000,
        });
        setTimeout(() => {
          navigate('/login', { 
            state: { 
              redirect: window.location.pathname,
              message: "Please login to manage your wishlist"
            } 
          });
        }, 1500);
      } else {
        toast.error("Failed to update wishlist", {
          description: errorMessage,
          duration: 3000,
        });
      }
    }
  };

  // Check if product is new (created within last 30 days)
  const isNewProduct = () => {
    if (!product.createdAt && !product.isNewArrival) return false;
    if (product.isNewArrival) return true;
    const createdDate = new Date(product.createdAt!);
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    return createdDate > thirtyDaysAgo;
  };

  // Check if product is featured
  const isFeaturedProduct = () => {
    return product.featured || product.isFeatured;
  };

  // Calculate discounted price
  const discountedPrice = product.discount > 0 
    ? product.price - (product.price * product.discount / 100)
    : product.price;

  return (
    <div
      className={`group relative bg-white rounded-xl shadow-sm overflow-hidden hover:shadow-lg transition-all duration-300 cursor-pointer ${
        product.hidden ? 'opacity-75 border-2 border-orange-200' : ''
      }`}
      onClick={handleCardClick}
    >
      {/* Product Image */}
      <div className="relative aspect-square overflow-hidden bg-gray-100">
        {/* Badges Container */}
        <div className="absolute top-2 left-2 z-10 flex flex-col gap-1">
          {product.discount > 0 && (
            <Badge variant="destructive" className="text-xs px-2 py-1">
              -{product.discount}%
            </Badge>
          )}
          {isFeaturedProduct() && (
            <Badge variant="default" className="bg-yellow-400 text-white text-xs px-2 py-1">
              ⭐ Featured
            </Badge>
          )}
          {isNewProduct() && (
            <Badge variant="default" className="bg-green-500 text-xs px-2 py-1">
              NEW
            </Badge>
          )}
          {product.isCustomizable && (
            <Badge variant="secondary" className="text-xs px-2 py-1 flex items-center gap-1">
              <Wand2 className="h-3 w-3" />
              Customizable
            </Badge>
          )}
          {product.hidden && (
            <Badge variant="outline" className="text-xs px-2 py-1 border-orange-500 text-orange-600">
              Hidden
            </Badge>
          )}
        </div>

        {/* Wishlist Button */}
        <button
          onClick={handleWishlistToggle}
          className="absolute top-2 right-2 z-10 p-1.5 rounded-full bg-white/80 hover:bg-white shadow-sm transition-colors duration-200"
        >
          <Heart
            className={cn(
              "h-4 w-4 transition-colors duration-200",
              isInWishlist ? "fill-red-500 stroke-red-500" : "stroke-gray-600"
            )}
          />
        </button>

        {/* Product Image */}
        <img
          src={getImageUrl(product.images[0]) || '/images/placeholder.svg'}
          alt={product.title}
          className={cn(
            "w-full h-full object-cover transition-opacity duration-300 group-hover:scale-110 group-hover:z-20",
            isImageLoaded ? "opacity-100" : "opacity-0"
          )}
          onLoad={() => setIsImageLoaded(true)}
          loading="lazy"
        />
        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors duration-300" />
      </div>

      {/* Product Info */}
      <div className="p-3">
        <h3 className="font-medium text-sm text-gray-900 mb-1 line-clamp-2 group-hover:text-primary transition-colors">
          {product.title}
        </h3>
        
        {/* Price */}
        <div className="flex items-center gap-1">
          {product.category === 'combos' && product.comboItems && product.comboItems.length > 0 ? (
            <span className={cn(
              "text-sm font-bold",
              product.discount > 0 ? "text-red-600" : "text-black"
            )}>
              {formatPrice(convertPrice(getComboMaxPrice(product)))}
            </span>
          ) : (
            <>
              <span className={cn(
                "text-sm font-bold",
                product.discount > 0 ? "text-red-600" : "text-black"
              )}>
                {formatPrice(convertPrice(product.discount ? product.price * (1 - product.discount / 100) : product.price))}
              </span>
              {product.discount > 0 && (
                <span className="text-xs text-gray-500 line-through">
                  {formatPrice(convertPrice(product.price))}
                </span>
              )}
            </>
          )}
        </div>

        {/* Action Buttons */}
        <div className="mt-3 flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            className={`flex-1 bg-primary text-white hover:bg-primary/90 hover:shadow-lg transition-all duration-200`}
            onClick={handleAddToCart}
          >
            <ShoppingBag className="h-4 w-4 mr-1" />
            Add to Cart
          </Button>
        </div>
      </div>
    </div>
  );
};

export default ProductGrid;