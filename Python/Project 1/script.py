import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load Data
df = pd.read_csv('finance_liquor_sales.csv')

# Basic Exploration
print("Initial Data Overview:")
print(df.info())
print(df.head())

# Clean text columns: strip() to remove spaces and title() to capitalize each word
df.columns = df.columns.str.strip().str.lower().str.replace(' ', '_')

# Convert 'date' to datetime
df['date'] = pd.to_datetime(df['date'], errors='coerce')

# Remove Duplicates
duplicates_count = df.duplicated().sum()
if duplicates_count > 0:
    print(f"Found {duplicates_count} duplicates. Removing them...")
    df = df.drop_duplicates()

# Handle Missing Data
missing_data = df.isna().sum()
print("Missing Values per Column:\n", missing_data)

# Drop rows with missing critical data
critical_columns = ['zip_code', 'item_description', 'bottles_sold', 'sale_dollars', 'store_name', 'date']
df.dropna(subset=critical_columns, inplace=True)

# Clean and Normalize Text Columns
text_columns = ['item_description', 'store_name', 'zip_code']
for col in text_columns:
    df[col] = df[col].astype(str).str.strip().str.title()

# Filter data for the range 2016–2019
df_filtered = df[(df['date'].dt.year >= 2016) & (df['date'].dt.year <= 2019)]

# Analysis Part 1: Most Popular Item Per Zip Code
popular_items = (
    df_filtered.groupby(['zip_code', 'item_description'])['bottles_sold']
    .sum()
    .reset_index()
)

popular_items = popular_items.loc[popular_items.groupby('zip_code')['bottles_sold'].idxmax()]

# Analysis Part 2: Sales Percentage Per Store
store_sales = (
    df_filtered.groupby('store_name')['sale_dollars']
    .sum()
    .reset_index()
)

store_sales['sales_percentage'] = (store_sales['sale_dollars'] / store_sales['sale_dollars'].sum()) * 100
store_sales.sort_values(by='sales_percentage', ascending=False, inplace=True)
top_n = store_sales.head(10)

# Visualization with Seaborn
plt.figure(figsize=(12, 6))
sns.barplot(
    x='sales_percentage',
    y='store_name',
    data=top_n,
    hue='store_name',
    legend=False,
    palette='viridis'
)
plt.title('Top 10 Stores by Sales Percentage (2016–2019) — Seaborn', fontsize=14)
plt.xlabel('Sales Percentage (%)')
plt.ylabel('Store Name')
plt.tight_layout()
plt.show()

# Visualization with Matplotlib
plt.figure(figsize=(12, 6))
plt.barh(top_n['store_name'], top_n['sales_percentage'], color='skyblue')
plt.title('Top 10 Stores by Sales Percentage (2016–2019) — Matplotlib', fontsize=14)
plt.xlabel('Sales Percentage (%)')
plt.ylabel('Store Name')
plt.gca().invert_yaxis()
plt.tight_layout()
plt.show()

# Export results for dashboards or reports
popular_items.to_csv('popular_items_by_zip.csv', index=False)
store_sales.to_csv('store_sales_percentages.csv', index=False)
