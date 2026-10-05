# Foodie Go

A simple Flutter food-ordering demo app with Home, Restaurants, Menu, Cart, Orders, Profile, and Razorpay Checkout integration.

## Payment setup

The app uses the official `razorpay_flutter` package. Replace `rzp_test_REPLACE_ME` in `lib/main.dart` with your Razorpay **TEST key ID** before testing payments. Never put the Razorpay `key_secret` in the mobile app. For production, create orders and verify payment signatures on a trusted backend.

Razorpay's Flutter plugin requires Android min SDK 19 or higher; this project uses min SDK 21. See the official Razorpay documentation for production order creation and signature verification.
