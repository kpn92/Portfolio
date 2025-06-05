import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Load the sample dataset
sample_file_path = '10-employees.csv'
sample_df = pd.read_csv(r'C:\WorkEarlyDataAnalysis\Employee Data Analysis\10-employees.csv')

# Group by performance score and calculate the average number of absences
perf_analysis = sample_df.groupby('PerformanceScore').agg({
    'Absences': 'mean'
}).reset_index()

# Plotting the results
plt.figure(figsize=(10, 6))
sns.barplot(x='PerformanceScore', y='Absences', data=perf_analysis, hue='PerformanceScore', dodge=False, palette='viridis')
plt.legend([],[], frameon=False)

# Adding titles and labels
plt.title('Average Number of Absences by Performance Score')
plt.xlabel('Performance Score')
plt.ylabel('Average Number of Absences')

# Show plot
plt.show()
