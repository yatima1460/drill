#pragma once

#include <string>
#include <filesystem>

namespace Drill
{
    namespace string_utils
    {
        bool tokenSearch(std::string main, std::string tokens);

        std::string to_lower(const std::string &);

        std::string time_to_string(const time_t& time);

        std::string size_to_string(size_t size);
    } // namespace string_utils
} // namespace Drill