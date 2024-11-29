#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=salon --tuples-only --no-align -c"

echo -e "\n~~~ Welcome to Ajo's salon ~~~\n"

SET_SERVICE_TIME() {
  # Receive service id and phone number as parameters
  SERVICE_ID=$1
  CUSTOMER_ID=$2

  echo -e "\nEnter appointment time"
  read SERVICE_TIME

  # Insert appointment into db
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) 
  VALUES($CUSTOMER_ID, $SERVICE_ID, '$SERVICE_TIME')")

  # Get service name and customer name from db
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID")
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id=$CUSTOMER_ID")

  # Print message to user
  echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  exit
}


CREATE_NEW_CUSTOMER() {
  # Receive service id and phone number as parameters
  SERVICE_ID_SELECTED=$1
  CUSTOMER_PHONE=$2

  # Enter phone into db
  # INSERT_CUSTOMER_PHONE=$($PSQL "INSERT INTO customers(phone) VALUES('$CUSTOMER_PHONE')")

  # Get customer name
  echo -e "\nNow please enter you name"
  read CUSTOMER_NAME

  # Insert customer into db
  INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")

  # Retrieve customer id from db
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

  # Call SET_SERVICE_TIME passing phone number as argument to complete booking
  SET_SERVICE_TIME $SERVICE_ID_SELECTED $CUSTOMER_ID
}


GET_CUSTOMER_PHONE() {
  SERVICE_ID_SELECTED=$1

  # Get customer phone number
  echo -e "\nTo complete your booking, we need some more information.\nFirst, please enter your phone number"
  read CUSTOMER_PHONE
  IS_CUSTOMER_IN_DB=$($PSQL "SELECT phone FROM customers WHERE phone='$CUSTOMER_PHONE'")

  if [[ -z $IS_CUSTOMER_IN_DB ]]
  then
    # If customer does not exist in db, create new customer
    CREATE_NEW_CUSTOMER $SERVICE_ID_SELECTED $CUSTOMER_PHONE
    return
  else
    # Retrieve customer id from db
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

    # Call SET_SERVICE_TIME to complete booking
    SET_SERVICE_TIME $SERVICE_ID_SELECTED $CUSTOMER_ID
    return
  fi
}

SELECT_SERVICE() {
  # Select a service
  echo -e "\nSelect a service by entering a number from the list above"
  read SERVICE_ID_SELECTED

  IS_SERVICE_ID_VALID=$($PSQL "SELECT service_id FROM services WHERE service_id='$SERVICE_ID_SELECTED'")
  
  # Check if selected service exists
  if [[ -z $IS_SERVICE_ID_VALID ]]
  then
    # If service not valid, return to main menu
    MAIN_MENU "Please select a valid service number."
    return
  else
    # Call GET_CUSTOMER_PHONE passing the service
    GET_CUSTOMER_PHONE $SERVICE_ID_SELECTED
  fi
}


MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  echo We offer the following services:

  SERVICES=$($PSQL "SELECT * FROM services ORDER BY service_id")
  echo "$SERVICES" | while IFS="|" read SERVICE_ID NAME
  do
    echo "$SERVICE_ID) $NAME"
  done

  SELECT_SERVICE
}


MAIN_MENU
