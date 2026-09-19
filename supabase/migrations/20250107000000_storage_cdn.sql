-- Bucket للمنتجات مع تحويلات الصور
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    TRUE,
    5242880, -- 5MB
    ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Bucket للشعارات
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('vendor-logos', 'vendor-logos', TRUE, 2097152)
ON CONFLICT (id) DO NOTHING;

-- سياسات رفع الصور للموردين
CREATE POLICY "Vendors upload product images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'product-images' AND
    (storage.foldername(name))[1] IN (
        SELECT id::text FROM vendors WHERE profile_id = auth.uid()
    )
);

CREATE POLICY "Anyone can view product images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'product-images');