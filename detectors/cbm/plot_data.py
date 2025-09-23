import pandas as pd
import plotly.graph_objects as go
import numpy as np

# Load the CSV file
df = pd.read_csv('output.csv', header=None, 
                 names=['TimeHigh', 'TimeLow', 'Type', 'Channel', 'ADC', 'NPos'])

print(f"Original data size: {len(df)}")

# Calculate time differences between consecutive TimeLow values
df['TimeDiff'] = df['TimeLow'].diff()

# Drop the first row which has NaN as time difference
time_diff_df = df.dropna(subset=['TimeDiff'])

# Count occurrences of each time difference value
time_diff_counts = time_diff_df['TimeDiff'].value_counts().reset_index()
time_diff_counts.columns = ['TimeDiff', 'Count']

# Sort by TimeDiff value
time_diff_counts = time_diff_counts.sort_values('TimeDiff')

print(f"Unique time differences: {len(time_diff_counts)}")
print("Most common time differences:")
print(time_diff_counts.sort_values('Count', ascending=False).head(10))

# # Create a bar chart of time difference frequencies
# fig = go.Figure()

# fig.add_trace(
#     go.Bar(
#         x=time_diff_counts['TimeDiff'],
#         y=time_diff_counts['Count'],
#         marker_color='blue',
#         opacity=0.7,
#         name='Time Difference Frequency'
#     )
# )

# # Update layout
# fig.update_layout(
#     title_text='Frequency of Time Differences Between Consecutive TimeLow Values',
#     xaxis_title='Time Difference',
#     yaxis_title='Count',
#     height=700,
#     width=1000,
#     paper_bgcolor='rgba(240, 240, 240, 0.95)',
#     plot_bgcolor='rgba(240, 240, 240, 0.95)',
#     hovermode='closest',
#     bargap=0.1
# )

# # Show the figure
# fig.show()

# # Save the figure
# fig.write_html('cbm_time_diff_histogram.html')

# # For very large number of unique time differences, you might want to bin them
# if len(time_diff_counts) > 50:
#     print("Creating binned histogram due to large number of unique values...")
    
#     fig2 = go.Figure()
    
#     fig2.add_trace(
#         go.Histogram(
#             x=time_diff_df['TimeDiff'],
#             nbinsx=50,
#             marker_color='green',
#             opacity=0.7,
#             name='Binned Time Difference Frequency'
#         )
#     )
    
#     # Update layout
#     fig2.update_layout(
#         title_text='Binned Histogram of Time Differences Between Consecutive TimeLow Values',
#         xaxis_title='Time Difference',
#         yaxis_title='Count',
#         height=700,
#         width=1000,
#         paper_bgcolor='rgba(240, 240, 240, 0.95)',
#         plot_bgcolor='rgba(240, 240, 240, 0.95)',
#         hovermode='closest'
#     )
    
#     # Show the figure
#     fig2.show()
    
#     # Save the figure
#     fig2.write_html('cbm_time_diff_binned_histogram.html')