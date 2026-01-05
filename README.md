# Grocery Store Data Analysis
Understanding grocery store data is essential in analyzing consumer behavior, pricing strategies, and product marketing in a highly competitive retail environment. With rising consumer interest in products that claim certain attributes, such as being health conscious or eco-friendly, grocery retailers must closely observe the various characteristics of products in their catalog and its effect on customer ratings, in order to optimize pricing, promotions, and inventory decisions.

Customer loyalty leads to repeat purchases over a long period of time, which creates a consistent cash flow for retail businesses. Product ratings can be used to determine whether consumers generally believe that a product is worth its price, or whether it lives up to its advertised consumer claim.

**BUSINESS PROBLEM:** How can a grocery store use pricing, customer ratings, and consumer-facing product claims from catalog data in order to make strategic business decisions that optimize customer loyalty? Which product traits tend to receive higher ratings from customers?

* ❌ Lower average rating → Customers are not satisfied with this product → Customers will search elsewhere for this product, or find a different store that regularly meets their needs → **Decrease in revenue**
* ✅ Higher average rating → Customers are satisfied with product quality → Customers will regularly return to this store to buy more → **Increase in revenue**

---
## Table of Contents
1. [Project Overview](#project-overview)
2. [Dataset Summary](#dataset-summary)
3. [Data Cleaning and Feature Engineering in **Python**](#data-cleaning-and-feature-engineering-in-python)
4. [Exploratory Data Analysis in **MySQL Workbench**](#exploratory-data-analysis-in-mysql-workbench)
5. [Visualizations in **Tableau Public**](#visualizations-in-tableau-public)
6. [Project Insight and Recommendations](#project-insight-and-recommendations)
7. [Conclusion](#conclusion)

---
## Project Overview
This project analyzes a retail dataset to understand how pricing, discounts, ratings, and consumer-facing product claims vary across different product categories. The data was cleaned and feature engineered in Python, then visualized using SQL queries and Tableau dashboards, in order to find business-oriented insights that would aid retail stakeholders in their merchandising and marketing decisions.

---
## Dataset Summary
The Kaggle dataset can be found [**here**](https://www.kaggle.com/datasets/bhavikjikadara/grocery-store-dataset). Each row represents a product scraped from Costco's online marketplace, and contains information about that product.
* **Size (Before Cleaning):** 1,757 rows, 8 columns
	* **Size (After Cleaning):** 1,751 rows, 14 columns
* **Retail Data:** Sub Category, Price, Discount, Rating, Title, Currency, Feature, Product Description
	* **Feature Engineered Columns (Binary Flags):** Is Clean Label, Is Eco Friendly, Is Health Conscious, Is High Quality, Is Plant Based, Is Shelf Stable, Has Religious Certification

‼️ **NOTE:** The "Currency" column was dropped from the dataset during the cleaning process, due to all of its values either being **`$`** or **`NULL`**, and therefore bringing no analytical insight into the data.

---
## Data Cleaning and Feature Engineering in Python
This dataset had some numerical columns that contained string values rather than numbers, which was corrected during the cleaning process. Also, the dataset had textual columns with values containing long descriptions, which were littered with symbols, unique characters, and information that would be useful for the data analysis. In order to extract this useful information, seven new columns were feature engineered using those long text strings.

### 1. All values in the **`discount`** column are written as descriptive text, and some contain a range of prices rather than a single discount value. Only the numerical discount will be extracted and preserved, in order to enhance querying and visualizations:
* **EX:** **`After $4.50 OFF`** → **`4.50`**
* **EX:** **`After $40 - $80 OFF`** → Find average between ranges → **`60`**
* **`No Discount`** → **`0`**
```python
# Define function to clean "discount" column
def clean_discount(value):
    
    if pd.isna(value):
        return np.nan

    # Replace "No Discount" with "0"
    if value.strip() == "No Discount":
        return 0.0

    # Extract numerical discount from string
    numbers = re.findall(r'\d+\.?\d*', value)

    if not numbers:
        return np.nan

    numbers = [float(num) for num in numbers]

    # If discount is a range between two numbers, extract its average
    if len(numbers) > 1:
        return sum(numbers) / len(numbers)

    # Return numerical discount value
    return numbers[0]

# Apply cleaning function
df['discount'] = df['discount'].apply(clean_discount)

# Replace empty fields with "0", to prevent errors during querying
df['discount'] = df['discount'].fillna(0)

# Make sure only the numerical discount was preserved
print(df['discount'].describe())
```

### 2. Some values in the **`price`** column contain a range between two numbers, such as **`$32.99through-$83.99`**, rather than a single value. Only the average between the two prices, such as **`58.49`**, will be extracted and preserved, in order to enhance querying and visualizations:
```python
# Define function to clean "price" column
def clean_price(value):
    
    if pd.isna(value):
        return np.nan

    value = str(value)

    # Extract numerical price from string
    if "through" in value.lower():
        numbers = re.findall(r'\d[\d,]*\.?\d*', value)
        numbers = [float(num.replace(',', '')) for num in numbers]

        # If price is a range between two numbers, extract its average
        if len(numbers) == 2:
            return round(sum(numbers) / 2, 2)

    # Make sure prices > 999.99 aren't mistakenly altered
    match = re.search(r'\d[\d,]*\.?\d*', value)
    if match:
        return round(float(match.group().replace(',', '')), 2)

    return np.nan

# Apply cleaning function
df['price'] = df['price'].apply(clean_price)

# Make sure only the numerical price was preserved, and prices > 999.99 weren't altered
print(df['price'].describe())
```

### 3. Most values in the **`title`**, **`feature`**, and **`product_description`** columns have quotes **`""`**, commas **`,`**, newline markers **`\n`**, non-ASCII characters **`è, â, í, õ, ü`**, and other inputs that may cause parsing issues. These will be removed, while the descriptive text will be preserved, in order to prevent parsing errors.
```python
# Define function to clean text columns
def clean_text(value):
    if pd.isna(value):
        return value

    value = str(value)

    # Replace newline characters with a space
    value = value.replace('\n', ' ').replace('\\n', ' ')

    # Remove non-ASCII characters
    value = value.encode('ascii', errors='ignore').decode('ascii')

    # Replace punctuation with a space
    value = re.sub(r'[^\w\s]', ' ', value)
    
    # Remove any remaining special characters
    value = re.sub(r'[^a-zA-Z0-9\s]', '', value)
    
    # Remove double spaces
    value = re.sub(r'\s+', ' ', value).strip()

    return value

# Apply cleaning function to text columns
text_columns = ['title', 'feature', 'product_description']

for col in text_columns:
    df[col] = df[col].apply(clean_text)

# Make sure text columns were cleaned
print(df[text_columns].head())
```

### 4. Most values in the **`title`**, **`feature`**, and **`product_description`** columns contain long text fields, with certain keywords that would be useful for data analysis. Create binary columns for each important product attribute. This will flag whether each product **`is_clean_label`**, **`is_eco_friendly`**, **`is_health_conscious`**, **`is_high_quality`**, **`is_plant_based`**, **`is_shelf_stable`**, or **`has_religious_certification`**. These new columns extract features from long text fields that are useful for querying and uncovering trends.
```python
# Combine "title", "feature", and "product_description" columns into one
df['combined_text'] = (
    df['title'].fillna('') + ' ' +
    df['feature'].fillna('') + ' ' +
    df['product_description'].fillna('')
)

# Name new binary columns, and assign appropriate keywords to each
keyword_groups = {
    'is_clean_label': ['organic', 'non gmo', 'all natural', 'no artificial', 'no additives', 'no added additives', 'no synthetic',
                       'no preservatives', 'no added preservatives', 'antibiotic free', 'no antibiotics', 'without antibiotics', 'usda',
                       'pesticide', 'pesticides', 'herbicide', 'herbicides', 'hormone', 'hormones', 'natural ingredients', 'chemical free'],
    
    'is_eco_friendly': ['eco friendly', 'sustainable', 'sustainably', 'sustainability', 'biodegradable', 'compostable', 'reusable',
                        'recycle', 'recycled', 'recyclable', 'plastic free', 'ethically sourced', 'zero waste', 'renewable'],
    
    'is_health_conscious': ['keto', 'paleo', 'low sugar', 'no sugar', '0g sugar', '0g sugars', 'zero sugar', 'no sugars', 'healthy gut',
                            '0g trans fat', 'trans fat free', 'low fat', 'no fat', 'low carb', 'no carb', 'high in fiber', 'antioxidants', 
                            'zero calorie', 'zero calories', 'no calorie', 'no calories', 'low calorie', 'low calories', 'healthy',
                            'low cholesterol', 'cholesterol free', 'no cholesterol', 'high protein', 'high in protein',
                            'low sodium', 'low in sodium', 'fat free', 'no added sugar', 'sugar free', 'heart healthy',
                            'low glycemic', 'good source of', 'excellent source of', '0g saturated fat', '0g sat fat'],
    
    'is_high_quality': ['high quality', 'artisan', 'artisanal', 'premium', 'luxury', 'luxurious',
                        'specialty', 'handcrafted', 'hand crafted', 'handmade', 'hand made'],
    
    'is_plant_based': ['plant based', 'vegan', 'vegetarian friendly', 'dairy free', 'non dairy', 'free of dairy', 'cruelty free'],
    
    'is_shelf_stable': ['shelf stable', 'shelf life', 'pantry', 'no refrigeration', 
                        'dried', 'canned', 'ready to eat', 'ready to serve'],
    
    'has_religious_certification': ['halal', 'certifiedhalal', 'kosherhalal', 'kosher',
                                    'koshercertified', 'certifiedkosher', 'verifiedkosher']
}

# Flag products in "combined_text" column with designated keywords
for col, keywords in keyword_groups.items():
    df[col] = df['combined_text'].str.lower().apply(
        lambda x: int(any(k in x for k in keywords))
    )
```

An in-depth [**Jupyter Notebook**](https://github.com/SunehraFarhana/Grocery-Store-Data-Analysis/blob/33dda2bd30d74b84559f5c3cf23f72d76fe1c426/grocery_store_dataset_cleaning.ipynb) detailing every step of the data cleaning process is available in this repository.

---
## Exploratory Data Analysis in MySQL Workbench
These SQL queries were used to reveal data trends and give guidance towards assembling visualizations.

### 1. What is the average price, discount, and rating by sub-category?
```sql
SELECT
    sub_category,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(discount), 2) AS avg_discount,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY sub_category
ORDER BY sub_category;
```
<img width="450" height="329" alt="grocery_store_sql_1" src="https://github.com/user-attachments/assets/117c387c-a0f6-4a77-9718-17760f1c6429" />


### 2. What is the total number of discounted products? Do discounted products receive higher ratings?
```sql
SELECT
    CASE
        WHEN discount > 0 THEN 'Discounted'
        ELSE 'Not Discounted'
    END AS discount_status,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY discount_status;
```
<img width="313" height="74" alt="grocery_store_sql_2" src="https://github.com/user-attachments/assets/5cdd79b4-7906-434c-98dc-053e93117e73" />


### 3. What is the total number of products per attribute, and its percent of the catalog? What is the average price, discount, and rating by attribute?
```sql
SELECT
    attribute,
    COUNT(*) AS product_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*)
		FROM grocery_store_schema.grocery_store_dataset_cleaned),2) AS pct_of_catalog,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(discount), 2) AS avg_discount,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM (
    SELECT 'is_clean_label' AS attribute, price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_clean_label = 1

    UNION ALL

    SELECT 'is_eco_friendly', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_eco_friendly = 1

    UNION ALL

    SELECT 'is_health_conscious', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_health_conscious = 1

    UNION ALL

    SELECT 'is_high_quality', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_high_quality = 1

    UNION ALL

    SELECT 'is_plant_based', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_plant_based = 1

    UNION ALL

    SELECT 'is_shelf_stable', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE is_shelf_stable = 1

    UNION ALL

    SELECT 'has_religious_certification', price, discount, average_rating
    FROM grocery_store_schema.grocery_store_dataset_cleaned
    WHERE has_religious_certification = 1
) t
GROUP BY attribute
ORDER BY pct_of_catalog DESC;
```
<img width="525" height="149" alt="grocery_store_sql_3" src="https://github.com/user-attachments/assets/7eb5ff3d-c89d-46de-a03f-70ae2e462c6a" />


### 4. How many products have multiple consumer claims? Do multi-claim products cost more? Do they receive higher ratings?
```sql
SELECT
    (is_clean_label
     + is_eco_friendly
     + is_health_conscious
     + is_high_quality
     + is_plant_based
     + is_shelf_stable
     + has_religious_certification) AS claim_count,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY claim_count
ORDER BY claim_count DESC;
```
<img width="293" height="135" alt="grocery_store_sql_4" src="https://github.com/user-attachments/assets/02056051-2279-4746-9ff8-8231259a7a25" />


### 5. What is the total number of clean label products? Do clean label products cost more? Do they receive higher ratings?
```sql
SELECT
    is_clean_label,
    COUNT(*) AS total_products,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(NULLIF(average_rating, 0)), 2) AS avg_rating
FROM grocery_store_schema.grocery_store_dataset_cleaned
GROUP BY is_clean_label;
```
<img width="302" height="76" alt="grocery_store_sql_5" src="https://github.com/user-attachments/assets/1cc24d05-2348-4cc5-ba9b-a3db9cd1ee0c" />


An in-depth [**SQL file**](https://github.com/SunehraFarhana/Grocery-Store-Data-Analysis/blob/fe73ad85b58a864adccbeefbe60aeca58f62452a/grocery_store_queries.sql) detailing every step of the querying process is available in this repository.

---
## Visualizations in Tableau Public
The Tableau Public visualizations can be found [**here**](https://public.tableau.com/views/grocery_store_visualizations/Start?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link). The data was organized into three dashboards, highlighting some baseline KPI's, the discount data, and data by product attribute. Users can easily navigate between these dashboards by clicking the buttons on the left side of the page. The average price, discount, and rating was used to paint a picture of how each product is valued.

<img width="1199" height="599" alt="grocery_store_visualizations_dashboard1_start" src="https://github.com/user-attachments/assets/4da2deb3-a70b-4b52-92de-9cfbbcb2037e" />

<img width="1199" height="599" alt="grocery_store_visualizations_dashboard2_baseline_kpi" src="https://github.com/user-attachments/assets/6ac68b63-a89d-45e5-86d2-5b9060bc8a08" />

<img width="1199" height="599" alt="grocery_store_visualizations_dashboard3_discount" src="https://github.com/user-attachments/assets/6e2a1a1b-dc2a-44a9-b749-b4980daf3043" />

<img width="1199" height="599" alt="grocery_store_visualizations_dashboard4_attribute" src="https://github.com/user-attachments/assets/16834d8f-f8ec-4f45-aca8-5d3dd301fa7a" />

---
## Project Insight and Recommendations
After feature-engineering binary columns for product attributes, doing exploratory data analysis, and creating graphic visualizations, the retail data reveals that:
* **Discounted products have a higher average rating than non-discounted products**.
	* **1,629 non-discounted products** make up about **93%** of the catalog, and have an average **rating of 4.33**.
 	* Whereas, **122 discounted products** make up about **7%** of the catalog, and have an average **rating of 4.58**.
    * Discounts may reduce profit, but they also increase customer satisfaction and the perceived value of a product, which results in brand trust and long-term loyalty.
	* ↳ Therefore, the grocery store should **increase targeted discounting, especially during holiday seasons** (e.g. promote 10% off of flowers, candy, and desserts during Valentine's Day, promote 20% off of food products and gift baskets during Christmas and Thanksgiving).
	* ↳ Also, **increase discounting in the most expensive sub-categories**, which are deli, meat, and seafood products, to reduce purchase hesitation.
* 
	* 
* 
	* 
* 
	* 
* 
	* 
* 
	* 

---
## Conclusion
This project transformed raw product listings scraped from Costco's online marketpalce into structured insights that inform pricing, marketing, and decision-making strategies in the retail industry. By focusing on customer satisfaction, grocery stores can mantain a growing loyal customer base that trusts their business to provide the products that they need, in good quality and at an affordable price.
